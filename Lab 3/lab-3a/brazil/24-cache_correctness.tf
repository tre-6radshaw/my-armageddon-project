#################################################
#1) Cache policy for static content (aggressive)
##############################################################

# Explanation: Static files are the easy win—Chewbacca caches them like hyperfuel for speed.
resource "aws_cloudfront_cache_policy" "gru_cache_static01" {
  name        = "${var.project_name}-cache-static01"
  comment     = "Aggressive caching for /static/*"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 60       ### updated from 0 to 60

  parameters_in_cache_key_and_forwarded_to_origin {
    # Explanation: Static should not vary on cookies—Chewbacca refuses to cache 10,000 versions of a PNG.
    cookies_config { cookie_behavior = "none" }

    # Explanation: Static should not vary on query strings (unless you do versioning); students can change later.
    query_strings_config { query_string_behavior = "none" }

    # Explanation: Keep headers out of cache key to maximize hit ratio.
    headers_config { header_behavior = "none" }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

############################################################
#2) Cache policy for API (safe default: caching disabled)
##############################################################



# Explanation: APIs are dangerous to cache by accident—Chewbacca disables caching until proven safe.
resource "aws_cloudfront_cache_policy" "gru_cache_api_disabled01" {
  name        = "${var.project_name}-cache-api-disabled01"
  comment     = "Disable caching for /api/* by default"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  # parameters_in_cache_key_and_forwarded_to_origin {
  #   cookies_config { 
  #     cookie_behavior = "all" 
  #     }
  #   query_strings_config { 
  #     query_string_behavior = "all" 
  #     }

  #   # Explanation: Forward auth-related headers to origin, but DO NOT include random headers in cache key.
  #   # Students: choose only required headers (Authorization is the classic case).
  #   headers_config {
  #     header_behavior = "whitelist"
  #     headers {
  #       items = ["Authorization", "Host"]  ###Removed Authorization
  #     }
  #   }

  #   # enable_accept_encoding_gzip   = true
  #   # enable_accept_encoding_brotli = true
  # }

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }

    # Explanation: Forward auth-related headers to origin, but DO NOT include random headers in cache key.
    # Students: choose only required headers (Authorization is the classic case).
    headers_config {
      header_behavior = "none"
    }

    # enable_accept_encoding_gzip   = true
    # enable_accept_encoding_brotli = true
  }
}

############################################################
#3) Origin request policy for API (forward what origin needs)
##############################################################


# Explanation: Origins need context—Chewbacca forwards what the app needs without polluting the cache key.
resource "aws_cloudfront_origin_request_policy" "gru_orp_api01" {
  name    = "${var.project_name}-orp-api01"
  comment = "Forward necessary values for API calls"

  cookies_config { cookie_behavior = "all" }
  query_strings_config { query_string_behavior = "all" }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Content-Type", "Origin", "Host"] ###Removed Authorization
    }
  }
}

##################################################################
# 4) Origin request policy for static (minimal)
##############################################################


# Explanation: Static origins need almost nothing—Chewbacca forwards minimal values for maximum cache sanity.
resource "aws_cloudfront_origin_request_policy" "gru_orp_static01" {
  name    = "${var.project_name}-orp-static01"
  comment = "Minimal forwarding for static assets"

  cookies_config { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "none" }
  headers_config { header_behavior = "none" }
}

##############################################################
# 5) Response headers policy (optional but nice)
##############################################################

# Explanation: Make caching intent explicit—Chewbacca stamps Cache-Control so humans and CDNs agree.
resource "aws_cloudfront_response_headers_policy" "gru_rsp_static01" {
  name    = "${var.project_name}-rsp-static01"
  comment = "Add explicit Cache-Control for static content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=86400, immutable"
    }
  }
}
