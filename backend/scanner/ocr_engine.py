"""
PurePick OCR Engine — Stage 1 of AI Pipeline
Extracts text from uploaded product label images.
Uses EasyOCR with fallback to Pillow-based preprocessing.
"""
import re
import logging
import numpy as np

logger = logging.getLogger(__name__)


def preprocess_image(image_path: str):
    """Enhance image for better OCR accuracy."""
    try:
        from PIL import Image, ImageFilter, ImageEnhance
        img = Image.open(image_path).convert('L')  # grayscale
        img = img.filter(ImageFilter.SHARPEN)
        enhancer = ImageEnhance.Contrast(img)
        img = enhancer.enhance(2.0)
        return img
    except Exception as e:
        logger.warning("Image preprocessing failed: %s", e)
        return None


def extract_text_easyocr(image_path: str) -> str:
    """Extract text using EasyOCR with preprocessed image."""
    try:
        import easyocr
        reader = easyocr.Reader(['en'], gpu=False, verbose=False)
        
        # Apply preprocessing
        img = preprocess_image(image_path)
        if img:
            # Convert PIL image to numpy array for EasyOCR
            image_input = np.array(img)
        else:
            image_input = image_path
            
        results = reader.readtext(image_input, detail=0, paragraph=True)
        return ' '.join(results)
    except Exception as e:
        logger.error("EasyOCR failed: %s", e)
        return ""


def extract_text_pil(image_path: str) -> str:
    """Fallback: basic PIL text hint (for demo if EasyOCR not installed)."""
    logger.warning("Using PIL fallback — install easyocr for real OCR")
    return ""


def extract_text_from_image(image_path: str) -> str:
    """
    Main OCR function. Returns raw extracted text from the image.
    """
    text = extract_text_easyocr(image_path)
    if not text:
        text = extract_text_pil(image_path)
    return text


def parse_ingredients_from_text(raw_text: str) -> list:
    """
    Parse ingredient list from raw OCR text with smart fallback.
    """
    if not raw_text:
        return []

    # Clean raw text from common OCR noise
    text = raw_text.lower()
    text = re.sub(r'[|\[\]{}«»]', '', text) # Remove common OCR artifacts

    # 1. Try to isolate section using keywords
    patterns = [
        r'(?:ingredients|ingrediente|ingrediente|ingred?nts?|composition|inci|formula|contains)[\s:=]+(.+?)(?:\.|\n\n|contains|warnings|directions|caution|produced|$)',
        r'(?:active ingredients)[\s:=]+(.+?)(?:\.|\n\n|inactive|$)',
        r'(?:inactive ingredients)[\s:=]+(.+?)(?:\.|\n\n|$)',
    ]

    ingredients_text = ""
    for pattern in patterns:
        match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
        if match:
            ingredients_text = match.group(1)
            break

    # 2. Fallback: If no section found, use the whole text but look for comma-density
    if not ingredients_text or len(ingredients_text.split(',')) < 2:
        ingredients_text = text

    # 3. Split on multiple delimiters
    raw_list = re.split(r'[,;•·\n\t]+', ingredients_text)

    # 4. Filter and clean items
    cleaned = []
    # Stop words to filter out common noise
    stop_words = {'ingredients', 'contains', 'warning', 'direction', 'caution', 'and', 'with', 'may', 'also'}
    
    for item in raw_list:
        item = item.strip()
        # Remove small symbols and numbers at the start/end
        item = re.sub(r'^[^a-z]+|[^a-z]+$', '', item)
        # Remove percentage annotations e.g. "(5%)"
        item = re.sub(r'\([\d.]+\s*%\)', '', item).strip()
        
        if len(item) > 2 and item not in stop_words:
            # If the item is too long, it might be a sentence; try to sub-split it
            if len(item) > 60:
                sub_parts = item.split('.')
                for sp in sub_parts:
                    sp = sp.strip()
                    if 2 < len(sp) < 60:
                        cleaned.append(sp)
            else:
                cleaned.append(item)

    # Dedup and limit
    seen = set()
    final_list = []
    for c in cleaned:
        if c not in seen:
            final_list.append(c)
            seen.add(c)

    return final_list[:60]

