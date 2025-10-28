#!/usr/bin/env python3
"""
Train Meta-Learning Models for Heterogeneity Prediction

This script trains machine learning models to predict:
- I² (heterogeneity percentage, 0-100%)
- τ² (between-study variance, ≥0)

From dataset characteristics:
- Number of studies (k)
- Outcome measure type
- Domain
- Year characteristics
- Sample size

Author: CBAMMR Development Team
Date: 2025-10-28
"""

import json
import numpy as np
import pandas as pd
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
from typing import Dict, Tuple, List
import warnings
warnings.filterwarnings('ignore')

from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import xgboost as xgb
import joblib


class MetaLearningPipeline:
    """Complete ML pipeline for heterogeneity prediction."""

    def __init__(self, data_path: str):
        self.data_path = Path(data_path)
        self.output_dir = Path("data/metalearning/models")
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self.df = None
        self.X_train = None
        self.X_val = None
        self.X_test = None
        self.y_train_i2 = None
        self.y_val_i2 = None
        self.y_test_i2 = None
        self.y_train_tau2 = None
        self.y_val_tau2 = None
        self.y_test_tau2 = None

        self.scaler = StandardScaler()
        self.label_encoders = {}

        self.rf_i2_model = None
        self.xgb_i2_model = None
        self.rf_tau2_model = None
        self.xgb_tau2_model = None

    def load_data(self):
        """Load training data."""
        print("Loading training data...")
        self.df = pd.read_csv(self.data_path)
        print(f"  Loaded {len(self.df)} samples")
        print(f"  Features: {list(self.df.columns)}")

    def feature_engineering(self):
        """Engineer features for ML models."""
        print("\nFeature engineering...")

        df = self.df.copy()

        # Create interaction features
        df['k_times_year_range'] = df['n_studies'] * df['year_range']
        df['k_squared'] = df['n_studies'] ** 2
        df['log_k'] = np.log(df['n_studies'])
        df['log_total_n'] = np.log(df['total_n'])
        df['log_ci_width'] = np.log(df['ci_width'].clip(lower=0.001))

        # Average sample size per study
        df['avg_n_per_study'] = df['total_n'] / df['n_studies']
        df['log_avg_n'] = np.log(df['avg_n_per_study'])

        # Study density (studies per year)
        df['studies_per_year'] = df['n_studies'] / df['year_range'].clip(lower=1)

        # Effect size indicators
        df['abs_pooled_effect'] = np.abs(df['pooled_effect'])
        df['large_effect'] = (df['abs_pooled_effect'] > 0.5).astype(int)

        # Year recency
        df['years_since_median'] = 2025 - df['year_median']

        # Q per study
        df['Q_per_study'] = df['Q'] / df['n_studies']

        # Sample size categories
        df['small_ma'] = (df['n_studies'] < 10).astype(int)
        df['large_ma'] = (df['n_studies'] > 30).astype(int)

        self.df = df

        print(f"  Created {len(self.df.columns)} features")

    def prepare_features(self) -> pd.DataFrame:
        """Prepare feature matrix."""
        print("\nPreparing features...")

        # Select features
        numeric_features = [
            'n_studies', 'year_median', 'year_range',
            'pooled_effect', 'ci_width', 'total_n',
            'k_times_year_range', 'k_squared', 'log_k',
            'log_total_n', 'log_ci_width', 'avg_n_per_study',
            'log_avg_n', 'studies_per_year', 'abs_pooled_effect',
            'years_since_median', 'Q_per_study'
        ]

        categorical_features = ['outcome_measure', 'domain']

        # Encode categorical features
        df_encoded = self.df[numeric_features].copy()

        for cat_feat in categorical_features:
            le = LabelEncoder()
            df_encoded[f'{cat_feat}_encoded'] = le.fit_transform(self.df[cat_feat])
            self.label_encoders[cat_feat] = le

        # Add binary features
        binary_features = ['small_ma', 'large_ma', 'large_effect']
        for feat in binary_features:
            df_encoded[feat] = self.df[feat]

        print(f"  Final feature count: {len(df_encoded.columns)}")
        print(f"  Feature names: {list(df_encoded.columns)}")

        return df_encoded

    def split_data(self, X: pd.DataFrame, test_size: float = 0.15,
                   val_size: float = 0.15, random_state: int = 42):
        """Split data into train/val/test sets."""
        print("\nSplitting data...")

        # Targets
        y_i2 = self.df['I2'].values
        y_tau2 = self.df['tau2'].values

        # First split: train+val vs test
        X_temp, self.X_test, y_temp_i2, self.y_test_i2, y_temp_tau2, self.y_test_tau2 = \
            train_test_split(X, y_i2, y_tau2, test_size=test_size,
                           random_state=random_state)

        # Second split: train vs val
        val_size_adjusted = val_size / (1 - test_size)
        self.X_train, self.X_val, self.y_train_i2, self.y_val_i2, \
            self.y_train_tau2, self.y_val_tau2 = \
            train_test_split(X_temp, y_temp_i2, y_temp_tau2,
                           test_size=val_size_adjusted,
                           random_state=random_state)

        # Scale features
        self.X_train = pd.DataFrame(
            self.scaler.fit_transform(self.X_train),
            columns=self.X_train.columns
        )
        self.X_val = pd.DataFrame(
            self.scaler.transform(self.X_val),
            columns=self.X_val.columns
        )
        self.X_test = pd.DataFrame(
            self.scaler.transform(self.X_test),
            columns=self.X_test.columns
        )

        print(f"  Train: {len(self.X_train)} samples")
        print(f"  Validation: {len(self.X_val)} samples")
        print(f"  Test: {len(self.X_test)} samples")

    def train_random_forest_i2(self):
        """Train Random Forest for I² prediction."""
        print("\n" + "="*80)
        print("Training Random Forest for I² Prediction")
        print("="*80)

        # Hyperparameter tuning
        param_grid = {
            'n_estimators': [300, 500],
            'max_depth': [10, 15, 20],
            'min_samples_split': [5, 10],
            'min_samples_leaf': [2, 4]
        }

        rf = RandomForestRegressor(random_state=42, n_jobs=-1)

        print("  Performing grid search with 5-fold CV...")
        grid_search = GridSearchCV(
            rf, param_grid, cv=5,
            scoring='neg_mean_absolute_error',
            n_jobs=-1, verbose=0
        )

        grid_search.fit(self.X_train, self.y_train_i2)

        self.rf_i2_model = grid_search.best_estimator_

        print(f"  Best parameters: {grid_search.best_params_}")
        print(f"  Best CV MAE: {-grid_search.best_score_:.2f}%")

        # Validation performance
        y_val_pred = self.rf_i2_model.predict(self.X_val)
        val_mae = mean_absolute_error(self.y_val_i2, y_val_pred)
        val_rmse = np.sqrt(mean_squared_error(self.y_val_i2, y_val_pred))
        val_r2 = r2_score(self.y_val_i2, y_val_pred)

        print(f"\n  Validation Performance:")
        print(f"    MAE:  {val_mae:.2f}%")
        print(f"    RMSE: {val_rmse:.2f}%")
        print(f"    R²:   {val_r2:.3f}")

    def train_xgboost_i2(self):
        """Train XGBoost for I² prediction."""
        print("\n" + "="*80)
        print("Training XGBoost for I² Prediction")
        print("="*80)

        # Hyperparameter tuning
        param_grid = {
            'n_estimators': [300, 500],
            'max_depth': [6, 8, 10],
            'learning_rate': [0.01, 0.05, 0.1],
            'subsample': [0.8, 1.0],
            'colsample_bytree': [0.8, 1.0]
        }

        xgb_model = xgb.XGBRegressor(random_state=42, n_jobs=-1)

        print("  Performing grid search with 5-fold CV...")
        grid_search = GridSearchCV(
            xgb_model, param_grid, cv=5,
            scoring='neg_mean_absolute_error',
            n_jobs=-1, verbose=0
        )

        grid_search.fit(self.X_train, self.y_train_i2)

        self.xgb_i2_model = grid_search.best_estimator_

        print(f"  Best parameters: {grid_search.best_params_}")
        print(f"  Best CV MAE: {-grid_search.best_score_:.2f}%")

        # Validation performance
        y_val_pred = self.xgb_i2_model.predict(self.X_val)
        val_mae = mean_absolute_error(self.y_val_i2, y_val_pred)
        val_rmse = np.sqrt(mean_squared_error(self.y_val_i2, y_val_pred))
        val_r2 = r2_score(self.y_val_i2, y_val_pred)

        print(f"\n  Validation Performance:")
        print(f"    MAE:  {val_mae:.2f}%")
        print(f"    RMSE: {val_rmse:.2f}%")
        print(f"    R²:   {val_r2:.3f}")

    def train_random_forest_tau2(self):
        """Train Random Forest for τ² prediction."""
        print("\n" + "="*80)
        print("Training Random Forest for τ² Prediction")
        print("="*80)

        param_grid = {
            'n_estimators': [300, 500],
            'max_depth': [10, 15, 20],
            'min_samples_split': [5, 10],
            'min_samples_leaf': [2, 4]
        }

        rf = RandomForestRegressor(random_state=42, n_jobs=-1)

        print("  Performing grid search with 5-fold CV...")
        grid_search = GridSearchCV(
            rf, param_grid, cv=5,
            scoring='neg_mean_absolute_error',
            n_jobs=-1, verbose=0
        )

        grid_search.fit(self.X_train, self.y_train_tau2)

        self.rf_tau2_model = grid_search.best_estimator_

        print(f"  Best parameters: {grid_search.best_params_}")
        print(f"  Best CV MAE: {-grid_search.best_score_:.4f}")

        # Validation performance
        y_val_pred = self.rf_tau2_model.predict(self.X_val)
        val_mae = mean_absolute_error(self.y_val_tau2, y_val_pred)
        val_rmse = np.sqrt(mean_squared_error(self.y_val_tau2, y_val_pred))
        val_r2 = r2_score(self.y_val_tau2, y_val_pred)

        print(f"\n  Validation Performance:")
        print(f"    MAE:  {val_mae:.4f}")
        print(f"    RMSE: {val_rmse:.4f}")
        print(f"    R²:   {val_r2:.3f}")

    def train_xgboost_tau2(self):
        """Train XGBoost for τ² prediction."""
        print("\n" + "="*80)
        print("Training XGBoost for τ² Prediction")
        print("="*80)

        param_grid = {
            'n_estimators': [300, 500],
            'max_depth': [6, 8, 10],
            'learning_rate': [0.01, 0.05, 0.1],
            'subsample': [0.8, 1.0],
            'colsample_bytree': [0.8, 1.0]
        }

        xgb_model = xgb.XGBRegressor(random_state=42, n_jobs=-1)

        print("  Performing grid search with 5-fold CV...")
        grid_search = GridSearchCV(
            xgb_model, param_grid, cv=5,
            scoring='neg_mean_absolute_error',
            n_jobs=-1, verbose=0
        )

        grid_search.fit(self.X_train, self.y_train_tau2)

        self.xgb_tau2_model = grid_search.best_estimator_

        print(f"  Best parameters: {grid_search.best_params_}")
        print(f"  Best CV MAE: {-grid_search.best_score_:.4f}")

        # Validation performance
        y_val_pred = self.xgb_tau2_model.predict(self.X_val)
        val_mae = mean_absolute_error(self.y_val_tau2, y_val_pred)
        val_rmse = np.sqrt(mean_squared_error(self.y_val_tau2, y_val_pred))
        val_r2 = r2_score(self.y_val_tau2, y_val_pred)

        print(f"\n  Validation Performance:")
        print(f"    MAE:  {val_mae:.4f}")
        print(f"    RMSE: {val_rmse:.4f}")
        print(f"    R²:   {val_r2:.3f}")

    def evaluate_final_models(self) -> Dict:
        """Evaluate all models on test set."""
        print("\n" + "="*80)
        print("Final Model Evaluation on Test Set")
        print("="*80)

        results = {}

        # Random Forest I²
        print("\nRandom Forest - I² Prediction:")
        rf_i2_pred = self.rf_i2_model.predict(self.X_test)
        rf_i2_mae = mean_absolute_error(self.y_test_i2, rf_i2_pred)
        rf_i2_rmse = np.sqrt(mean_squared_error(self.y_test_i2, rf_i2_pred))
        rf_i2_r2 = r2_score(self.y_test_i2, rf_i2_pred)
        print(f"  MAE:  {rf_i2_mae:.2f}%")
        print(f"  RMSE: {rf_i2_rmse:.2f}%")
        print(f"  R²:   {rf_i2_r2:.3f}")

        results['rf_i2'] = {
            'mae': float(rf_i2_mae),
            'rmse': float(rf_i2_rmse),
            'r2': float(rf_i2_r2),
            'predictions': rf_i2_pred.tolist()
        }

        # XGBoost I²
        print("\nXGBoost - I² Prediction:")
        xgb_i2_pred = self.xgb_i2_model.predict(self.X_test)
        xgb_i2_mae = mean_absolute_error(self.y_test_i2, xgb_i2_pred)
        xgb_i2_rmse = np.sqrt(mean_squared_error(self.y_test_i2, xgb_i2_pred))
        xgb_i2_r2 = r2_score(self.y_test_i2, xgb_i2_pred)
        print(f"  MAE:  {xgb_i2_mae:.2f}%")
        print(f"  RMSE: {xgb_i2_rmse:.2f}%")
        print(f"  R²:   {xgb_i2_r2:.3f}")

        results['xgb_i2'] = {
            'mae': float(xgb_i2_mae),
            'rmse': float(xgb_i2_rmse),
            'r2': float(xgb_i2_r2),
            'predictions': xgb_i2_pred.tolist()
        }

        # Random Forest τ²
        print("\nRandom Forest - τ² Prediction:")
        rf_tau2_pred = self.rf_tau2_model.predict(self.X_test)
        rf_tau2_mae = mean_absolute_error(self.y_test_tau2, rf_tau2_pred)
        rf_tau2_rmse = np.sqrt(mean_squared_error(self.y_test_tau2, rf_tau2_pred))
        rf_tau2_r2 = r2_score(self.y_test_tau2, rf_tau2_pred)
        print(f"  MAE:  {rf_tau2_mae:.4f}")
        print(f"  RMSE: {rf_tau2_rmse:.4f}")
        print(f"  R²:   {rf_tau2_r2:.3f}")

        results['rf_tau2'] = {
            'mae': float(rf_tau2_mae),
            'rmse': float(rf_tau2_rmse),
            'r2': float(rf_tau2_r2),
            'predictions': rf_tau2_pred.tolist()
        }

        # XGBoost τ²
        print("\nXGBoost - τ² Prediction:")
        xgb_tau2_pred = self.xgb_tau2_model.predict(self.X_test)
        xgb_tau2_mae = mean_absolute_error(self.y_test_tau2, xgb_tau2_pred)
        xgb_tau2_rmse = np.sqrt(mean_squared_error(self.y_test_tau2, xgb_tau2_pred))
        xgb_tau2_r2 = r2_score(self.y_test_tau2, xgb_tau2_pred)
        print(f"  MAE:  {xgb_tau2_mae:.4f}")
        print(f"  RMSE: {xgb_tau2_rmse:.4f}")
        print(f"  R²:   {xgb_tau2_r2:.3f}")

        results['xgb_tau2'] = {
            'mae': float(xgb_tau2_mae),
            'rmse': float(xgb_tau2_rmse),
            'r2': float(xgb_tau2_r2),
            'predictions': xgb_tau2_pred.tolist()
        }

        # Select best models
        best_i2_model = 'xgb' if xgb_i2_mae < rf_i2_mae else 'rf'
        best_tau2_model = 'xgb' if xgb_tau2_mae < rf_tau2_mae else 'rf'

        print(f"\n{'='*80}")
        print(f"Best Model for I²: {best_i2_model.upper()} (MAE: "
              f"{results[f'{best_i2_model}_i2']['mae']:.2f}%)")
        print(f"Best Model for τ²: {best_tau2_model.upper()} (MAE: "
              f"{results[f'{best_tau2_model}_tau2']['mae']:.4f})")
        print(f"{'='*80}")

        results['best_models'] = {
            'i2': best_i2_model,
            'tau2': best_tau2_model
        }

        return results

    def feature_importance_analysis(self):
        """Analyze feature importance."""
        print("\n" + "="*80)
        print("Feature Importance Analysis")
        print("="*80)

        # Get feature importance from Random Forest (I²)
        importances = self.rf_i2_model.feature_importances_
        feature_names = self.X_train.columns

        # Sort by importance
        indices = np.argsort(importances)[::-1]

        print("\nTop 10 Most Important Features (for I² prediction):")
        for i in range(min(10, len(feature_names))):
            idx = indices[i]
            print(f"  {i+1}. {feature_names[idx]:25s}: {importances[idx]:.4f}")

        # Save feature importance
        importance_dict = {
            feature_names[i]: float(importances[i])
            for i in range(len(feature_names))
        }

        importance_file = self.output_dir / "feature_importance.json"
        with open(importance_file, 'w') as f:
            json.dump(importance_dict, f, indent=2)

        print(f"\n✅ Saved feature importance to: {importance_file}")

    def save_models(self):
        """Save all trained models."""
        print("\n" + "="*80)
        print("Saving Models")
        print("="*80)

        # Save Random Forest models
        joblib.dump(self.rf_i2_model, self.output_dir / "rf_i2_model.pkl")
        print("  ✅ Saved: rf_i2_model.pkl")

        joblib.dump(self.rf_tau2_model, self.output_dir / "rf_tau2_model.pkl")
        print("  ✅ Saved: rf_tau2_model.pkl")

        # Save XGBoost models
        joblib.dump(self.xgb_i2_model, self.output_dir / "xgb_i2_model.pkl")
        print("  ✅ Saved: xgb_i2_model.pkl")

        joblib.dump(self.xgb_tau2_model, self.output_dir / "xgb_tau2_model.pkl")
        print("  ✅ Saved: xgb_tau2_model.pkl")

        # Save preprocessing objects
        joblib.dump(self.scaler, self.output_dir / "scaler.pkl")
        print("  ✅ Saved: scaler.pkl")

        joblib.dump(self.label_encoders, self.output_dir / "label_encoders.pkl")
        print("  ✅ Saved: label_encoders.pkl")

        # Save feature names
        feature_names = {
            'features': list(self.X_train.columns),
            'n_features': len(self.X_train.columns)
        }
        with open(self.output_dir / "feature_names.json", 'w') as f:
            json.dump(feature_names, f, indent=2)
        print("  ✅ Saved: feature_names.json")

    def run_complete_pipeline(self):
        """Run the complete ML pipeline."""
        print("\n" + "="*80)
        print("CBAMMR Meta-Learning Pipeline")
        print("="*80)

        # Load and prepare data
        self.load_data()
        self.feature_engineering()
        X = self.prepare_features()
        self.split_data(X)

        # Train models
        self.train_random_forest_i2()
        self.train_xgboost_i2()
        self.train_random_forest_tau2()
        self.train_xgboost_tau2()

        # Evaluate
        results = self.evaluate_final_models()

        # Feature importance
        self.feature_importance_analysis()

        # Save everything
        self.save_models()

        # Save results
        results_file = self.output_dir / "evaluation_results.json"
        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\n✅ Saved evaluation results to: {results_file}")

        print("\n" + "="*80)
        print("✅ Pipeline Complete!")
        print("="*80)

        return results


def main():
    """Main execution."""
    data_path = "data/metalearning/training/metalearning_training_data.csv"

    pipeline = MetaLearningPipeline(data_path)
    results = pipeline.run_complete_pipeline()

    return pipeline, results


if __name__ == "__main__":
    pipeline, results = main()
