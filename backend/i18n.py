"""أداة ترجمة بسيطة للنصوص المولّدة في الخادم."""


def t(lang: str, ar: str, en: str) -> str:
    return en if lang == "en" else ar
