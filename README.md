# Nginx Smart Proxy Pass

The smart proxy pass lua script for nginx to pass request smartly, by verify API-KEY from subdomain for give access to target host

## Content

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Requirements

1. [Nginx](https://nginx.org) server.
2. [lua-nginx-module](https://github.com/openresty/lua-nginx-module) builded-in with nginx (Note: you can use [OpenResty](https://openresty.org))
3. [lua-resty-http](https://github.com/ledgetech/lua-resty-http) lua module.

## Installation

1. Clone the repository.
    ```bash
    git clone https://github.com/AbdoPrDz/ngx-smart-proxy-pass.git
    ```

2. There is a ready bash script to install the script:
  - First, create a specified folder for custom lua scripts.
  - Then, add custom lua scripts in the nginx configuration.
    ```conf
    http {
      ...
      
      lua_package_path "/usr/local/openresty/nginx/lua-scripts/?.lua;;";
      
      ...
    }
    ```
  - Run the install script `~/ngx-smart-proxy-pass/install.sh`:
    - Usage:
      - Smart-Proxy-Pass Install Script
      - Version: 1.0.1
      - Usage: install.sh <project_path> [lua_scripts_path] [auth_json_path] [log_path] [engine]
        - project_path: Path to the project directory
        - lua_scripts_path: (Optional) Path to the lua-scripts directory (default: /etc/nginx/lua-scripts)
        - auth_json_path: (Optional) Path to the auth.json file (default: /etc/smart-proxy-pass/auth.json)
        - log_path: (Optional) Path to the logs directory (default: /var/log/smart-proxy-pass.log)
        - engine: (Optional) The server engine you use (default: nginx)
      - Example
        ```bash
        ./install.sh ~/ngx-smart "/usr/local/openresty/nginx/lua-scripts" "/home/abdopr/smart-proxy-pass-auth.json" "/home/abdopr/smart-proxy-pass.log" "openresty"
        ```
    - Set your `$auth_json_path` and `$log_path` variables in your nginx config file:
      ```conf
        server {
          set $log_path "/home/abdopr/smart-proxy-pass.log"

          ...
        }
      ``` 

## Usage

1. Edit your nginx conf and create a `access_by_lua_block` block then put this script

    `nginx.conf` example:
    ```conf
    server {
        listen 80;
        server_name *.localhost;

        location / {
            set $target "";
            set $proxy_host "";
            set $log_path "/home/abdopr/smart-proxy-pass.log";

            access_by_lua_block {
                local spp_access = require("spp.access")

                -- Using host access
                local res = spp_access(ngx, "http://127.0.0.1:5000/auth/check", nil)

                -- Using local auth json file
                local res = spp_access(ngx, nil, "/home/abdopr/smart-proxy-pass-auth.json")
                
                if res.success and res.target then
                    local host = res.target
                    ngx.var.target = "https://" .. host
                    ngx.var.proxy_host = host
                end
            }

            proxy_pass $target;
            proxy_set_header Host $proxy_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # SSL Settings
            proxy_ssl_server_name on;
            proxy_ssl_verify off;

            # Buffer Size Settings
            proxy_buffer_size 16k;
            proxy_buffers 4 32k;
            proxy_busy_buffers_size 64k;
        }

        location ~ /\.ht {
            deny all;
        }
    }
    ```

2. When you use local access method you should provide the auth json file.
    `auth.json` example:
    ```json
    {
      "glg": {
        "key": "glg",
        "target_host": "www.google.com",
      },
      "api_key2": {
        "key": "api_key2",
        "target_host": "www.facebook.com",
      }
    }
    ```

3. When you use host access method you need to create host endpoint to verify the API-KEY and return the target host

    `flask_app.py` example:
    ```python
    import flask
    from flask import Response, request, jsonify


    app: flask.Flask = flask.Flask(__name__)
    app.config["DEBUG"] = True


    def api_response(success: bool, message: str, data: dict, status: int = 200) -> Response:
      return jsonify({
        'success': success,
        'message': message,
        **data,
      }), status

    def api_error(message: str, status: int = 400):
      return api_response(False, message, {}, status)

    def api_success(message: str, data: dict = {}, status: int = 200):
      return api_response(True, message, data, status)

    @app.route('/auth/check', methods=['POST'])
    def check_auth():
      data = request.get_json()
      api_key = data['API-KEY']
      
      print(f"API-KEY: {api_key}")

      # your verify script
      
      if api_key == 'api_key':
        return api_success('Authentication success', {"target_host": "www.google.com"})
      else:
        return api_error('Authentication failed', 401)

    if __name__ == '__main__':
      app.run(host="0.0.0.0", port=5000)
    ```

    Note: Your auth check endpoint should returns json response with this form (is important):
    ```json
    {
      "success": true,
      "message": "your-message",
      "target_host": "target-host-on-sucess" 
    }
    ```

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/AbdoPrDZ/ngx-smart-proxy-pass/blob/main/LICENSE.md) file for details.
