#!/usr/bin/env python3
"""
Prediction script for CBAMMR meta-learning integration.

This script loads trained models and makes predictions for new meta-analyses.
Called by R functions via system() command.

Author: CBAMMR Development Team
Date: 2025-10-28
"""

import sys
import json
import numpy as np
import pandas as pd
import joblib
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')


def load_models():
    """
    Load all trained models and preprocessing objects.

    SECURITY NOTE: This function loads pickled ML models using joblib.
    Only use with models from trusted sources. Loading untrusted pickle
    files can execute arbitrary code.

    Raises:
        FileNotFoundError: If model files are missing
        Exception: If model loading fails
    """
    models_dir = Path(__file__).parent.parent / "data/metalearning/models"

    # Verify models directory exists
    if not models_dir.exists():
        raise FileNotFoundError(
            f"Models directory not found: {models_dir}\n"
            "Run train_metalearning_models.py first to create models."
        )

    # Define required model files
    required_files = {
        'rf_i2': "rf_i2_model.pkl",
        'rf_tau2': "rf_tau2_model.pkl",
        'xgb_i2': "xgb_i2_model.pkl",
        'xgb_tau2': "xgb_tau2_model.pkl",
        'scaler': "scaler.pkl",
        'label_encoders': "label_encoders.pkl"
    }

    # Check all files exist before loading
    missing_files = []
    for name, filename in required_files.items():
        if not (models_dir / filename).exists():
            missing_files.append(filename)

    if missing_files:
        raise FileNotFoundError(
            f"Missing required model files: {', '.join(missing_files)}\n"
            "Run train_metalearning_models.py to create all models."
        )

    # Load models with error handling
    models = {}
    try:
        for name, filename in required_files.items():
            models[name] = joblib.load(models_dir / filename)
    except Exception as e:
        raise Exception(f"Failed to load model {filename}: {str(e)}")

    # Load feature names
    feature_file = models_dir / "feature_names.json"
    if not feature_file.exists():
        raise FileNotFoundError(f"Feature names file not found: {feature_file}")

    try:
        with open(feature_file) as f:
            models['feature_names'] = json.load(f)['features']
    except Exception as e:
        raise Exception(f"Failed to load feature names: {str(e)}")

    return models


def prepare_features(input_data: dict, models: dict) -> np.ndarray:
    """
    Prepare features for prediction.

    Args:
        input_data: Dictionary with:
            - n_studies: Number of studies (REQUIRED)
            - outcome_measure: "OR", "RR", "SMD", "MD", "HR", "COR" (REQUIRED)
            - domain: Research domain (optional, default: "cardiology")
            - year_median: Median publication year (optional, default: 2020)
            - year_range: Range of publication years (optional, default: 10)
            - pooled_effect: Pooled effect size (optional, default: 0.5)
            - ci_width: Confidence interval width (optional, default: 0.2)
            - total_n: Total sample size (optional, default: n_studies * 100)
            - Q: Cochran's Q statistic (optional, computed from n_studies)

    Returns:
        Feature array ready for prediction

    Raises:
        ValueError: If required fields are missing or invalid
    """
    # Validate required fields
    if 'n_studies' not in input_data:
        raise ValueError("Required field 'n_studies' is missing")
    if 'outcome_measure' not in input_data:
        raise ValueError("Required field 'outcome_measure' is missing")

    # Extract and validate n_studies
    try:
        n_studies = int(input_data['n_studies'])
        if n_studies < 2:
            raise ValueError("n_studies must be at least 2")
        if n_studies > 10000:
            raise ValueError("n_studies cannot exceed 10000 (likely data error)")
    except (TypeError, ValueError) as e:
        raise ValueError(f"Invalid n_studies value: {str(e)}")

    # Validate outcome_measure
    outcome_measure = input_data['outcome_measure']
    valid_measures = ["OR", "RR", "SMD", "MD", "HR", "COR", "RD"]
    if outcome_measure not in valid_measures:
        raise ValueError(
            f"Invalid outcome_measure '{outcome_measure}'. "
            f"Must be one of: {', '.join(valid_measures)}"
        )

    # Extract values with defaults and validation
    year_median = input_data.get('year_median', 2020)
    year_range = input_data.get('year_range', 10)
    pooled_effect = input_data.get('pooled_effect', 0.5)
    ci_width = input_data.get('ci_width', 0.2)
    total_n = input_data.get('total_n', n_studies * 100)
    Q = input_data.get('Q', n_studies * 2)  # Default Q if not provided

    # Compute derived features
    k_times_year_range = n_studies * year_range
    k_squared = n_studies ** 2
    log_k = np.log(n_studies)
    log_total_n = np.log(total_n)
    log_ci_width = np.log(max(ci_width, 0.001))
    avg_n_per_study = total_n / n_studies
    log_avg_n = np.log(avg_n_per_study)
    studies_per_year = n_studies / max(year_range, 1)
    abs_pooled_effect = abs(pooled_effect)
    years_since_median = 2025 - year_median
    Q_per_study = Q / n_studies
    small_ma = 1 if n_studies < 10 else 0
    large_ma = 1 if n_studies > 30 else 0
    large_effect = 1 if abs_pooled_effect > 0.5 else 0

    # Encode categorical features
    outcome_measure = input_data['outcome_measure']
    domain = input_data.get('domain', 'cardiology')

    le_outcome = models['label_encoders']['outcome_measure']
    le_domain = models['label_encoders']['domain']

    # Handle unseen categories
    if outcome_measure not in le_outcome.classes_:
        outcome_encoded = 0  # Default to first class
    else:
        outcome_encoded = le_outcome.transform([outcome_measure])[0]

    if domain not in le_domain.classes_:
        domain_encoded = 0  # Default to first class
    else:
        domain_encoded = le_domain.transform([domain])[0]

    # Build feature vector
    features = np.array([
        n_studies, year_median, year_range, pooled_effect, ci_width, total_n,
        k_times_year_range, k_squared, log_k, log_total_n, log_ci_width,
        avg_n_per_study, log_avg_n, studies_per_year, abs_pooled_effect,
        years_since_median, Q_per_study, outcome_encoded, domain_encoded,
        small_ma, large_ma, large_effect
    ]).reshape(1, -1)

    # Scale features
    features_scaled = models['scaler'].transform(features)

    return features_scaled


def predict_heterogeneity(input_data: dict, model_type: str = 'rf') -> dict:
    """
    Predict I² and τ² for a meta-analysis.

    Args:
        input_data: Dictionary with meta-analysis characteristics
        model_type: "rf" or "xgb"

    Returns:
        Dictionary with predictions and confidence
    """
    # Load models
    models = load_models()

    # Prepare features
    X = prepare_features(input_data, models)

    # Make predictions
    if model_type == 'rf':
        i2_pred = models['rf_i2'].predict(X)[0]
        tau2_pred = models['rf_tau2'].predict(X)[0]
    else:  # xgb
        i2_pred = models['xgb_i2'].predict(X)[0]
        tau2_pred = models['xgb_tau2'].predict(X)[0]

    # Clip to valid ranges
    i2_pred = np.clip(i2_pred, 0, 100)
    tau2_pred = np.clip(tau2_pred, 0, None)

    # Categorize I²
    if i2_pred < 25:
        i2_category = "low"
        interpretation = "Low heterogeneity. Consider fixed-effect model."
    elif i2_pred < 50:
        i2_category = "moderate"
        interpretation = "Moderate heterogeneity. Random-effects recommended."
    elif i2_pred < 75:
        i2_category = "substantial"
        interpretation = "Substantial heterogeneity. Explore moderators."
    else:
        i2_category = "considerable"
        interpretation = "Considerable heterogeneity. Subgroup analysis essential."

    # Estimate uncertainty (based on test set MAE)
    i2_uncertainty = 11.51  # MAE from test set
    tau2_uncertainty = 0.3006

    results = {
        'predicted_I2': round(float(i2_pred), 2),
        'predicted_tau2': round(float(tau2_pred), 4),
        'I2_category': i2_category,
        'I2_uncertainty': i2_uncertainty,
        'tau2_uncertainty': tau2_uncertainty,
        'interpretation': interpretation,
        'model_used': model_type,
        'recommendation': get_recommendation(i2_pred, input_data['n_studies'])
    }

    return results


def get_recommendation(predicted_i2: float, n_studies: int) -> str:
    """Get methodological recommendations based on predicted heterogeneity."""
    recommendations = []

    if predicted_i2 < 25:
        recommendations.append("Low heterogeneity expected. Fixed-effect model may be appropriate.")
    else:
        recommendations.append("Random-effects model recommended.")

    if predicted_i2 > 50:
        recommendations.append("Explore moderators through meta-regression or subgroup analysis.")

    if predicted_i2 > 75:
        recommendations.append("Consider narrative synthesis if heterogeneity cannot be explained.")

    if n_studies < 10:
        recommendations.append(f"Small meta-analysis (k={n_studies}). Consider using Hartung-Knapp-Sidik-Jonkman method.")

    if n_studies < 20 and predicted_i2 > 50:
        recommendations.append("Collect more studies to increase statistical power.")

    return " ".join(recommendations)


def main():
    """Main execution for command-line interface."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No input provided"}))
        sys.exit(1)

    # Parse input JSON
    try:
        input_data = json.loads(sys.argv[1])
    except json.JSONDecodeError:
        print(json.dumps({"error": "Invalid JSON input"}))
        sys.exit(1)

    # Get model type
    model_type = input_data.pop('model_type', 'rf')

    # Make prediction
    try:
        results = predict_heterogeneity(input_data, model_type)
        print(json.dumps(results))
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
