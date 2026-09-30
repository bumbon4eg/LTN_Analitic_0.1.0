import ssl


def get_database_ssl_option(enabled: bool) -> ssl.SSLContext | bool:
    if not enabled:
        return False
    return ssl.create_default_context()