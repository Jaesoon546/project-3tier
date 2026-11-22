"""학교 등록 폼 검사"""

HOMEPAGE_MAX = 200


def check_homepage(value):
    """홈페이지 주소 → (주소 또는 None, 에러 메시지)
    http:// 나 https:// 로 시작하는 주소만 받음 — 'javascript:' 같은 주소를 링크에 넣지 못하게"""
    url = (value or '').strip()
    if not url:
        return None, None            # 비워 두면 사진만 보이고 링크는 없음
    if not url.lower().startswith(('http://', 'https://')):
        return None, '홈페이지는 http:// 또는 https:// 로 시작해야 합니다.'
    if len(url) > HOMEPAGE_MAX or any(c.isspace() for c in url):
        return None, '홈페이지 주소를 확인하세요.'
    return url, None
