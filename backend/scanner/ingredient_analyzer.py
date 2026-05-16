"""
PurePick Ingredient Analyzer — Phase III Professional Pipeline
Uses Stage 3.5 Ingredient Intelligence Layer
"""
import os
import logging
from django.conf import settings
from .ingredient_intelligence import run_ingredient_intelligence

logger = logging.getLogger(__name__)

class IngredientAnalyzer:
    _instance = None

    def __init__(self):
        # The intelligence layer is stateless and handled in its own module
        pass

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def analyze(self, ingredients: list, user_profile: dict) -> dict:
        """
        Phase III Pipeline Entry Point
        Stage 1-2: Handled by views/OCR
        Stage 3.5: Ingredient Intelligence Layer (Resolution + Profile Match + Scoring)
        Stage 6: Final Report Generation
        """
        # Run the Intelligence Layer
        intel_report = run_ingredient_intelligence(ingredients, user_profile)
        
        # Format the final report for the mobile app
        allergy_alerts = []
        for item in intel_report['flagged_ingredients']:
            severity = item.get('severity', 'MODERATE')
            color = "#FF3B30" if severity == "CRITICAL" else "#FF9500" if severity == "MODERATE" else "#FFCC00"
            banner = "DO NOT USE" if severity == "CRITICAL" else "USE WITH CAUTION"
            
            allergy_alerts.append({
                "ingredient": item['raw_ingredient'],
                "common_name": item['common_name'],
                "matched_concern": item['matched_concern'],
                "severity": severity,
                "display_color": color,
                "banner": f"{banner} — Contains your concern",
                "plain_explanation": item['explanation']
            })

        # Overall Verdict
        risk_band = intel_report['risk_band']
        verdict_color = "#FF3B30" if risk_band == "High Risk" else "#FF9500" if risk_band == "Moderate" else "#34C759"
        icon = "BLOCKED" if risk_band == "High Risk" else "WARNING" if risk_band == "Moderate" else "SAFE"

        safety_score = 100 - min(100, intel_report['total_risk_score'])
        
        # Safety catch: If no ingredients were flagged, it must be 100% safe
        if not allergy_alerts and safety_score < 50:
            safety_score = 100

        return {
            "overall_score": safety_score,
            "risk": {
                "total_score": intel_report['total_risk_score'],
                "risk_band": risk_band
            },
            "allergy_result": {
                "overall_verdict": risk_band.upper(),
                "verdict_color": verdict_color,
                "verdict_icon": icon,
                "allergy_alerts": allergy_alerts,
                "safe_ingredients": intel_report['safe_ingredients'],
                "total_alerts": len(allergy_alerts),
                "total_safe": len(intel_report['safe_ingredients'])
            },
            "ingredient_breakdown": intel_report['all_ingredients']
        }

# Singleton instance
_analyzer = None

def get_analyzer():
    global _analyzer
    if _analyzer is None:
        _analyzer = IngredientAnalyzer()
    return _analyzer
