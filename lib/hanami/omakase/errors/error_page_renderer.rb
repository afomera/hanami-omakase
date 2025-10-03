# frozen_string_literal: true

module Hanami
  module Omakase
    module Errors
      class ErrorPageRenderer
        def initialize(error, request = nil)
          @error = error
          @request = request
        end

        def render
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>#{error_title}</title>
                #{css_styles}
            </head>
            <body>
                <div class="error-container">
                    <div class="error-header">
                        <h1>#{error_class_name}</h1>
                    </div>

                    <div class="error-message">
                        <h2>#{error_message}</h2>
                        #{render_action_buttons}
                    </div>

                    <div class="error-details">
                        #{render_backtrace}
                        #{render_request_info}
                        #{render_environment_info}
                    </div>
                </div>
                #{javascript}
            </body>
            </html>
          HTML
        end

        private

        attr_reader :error, :request

        def error_title
          "#{error_class_name} at #{request_path}"
        end

        def error_class_name
          @error.class.name
        end

        def error_message
          @error.message
        end

        def request_path
          request&.path_info || "/"
        end

        def render_action_buttons
          return "" unless actionable_error?

          buttons = @error.actions.map do |name, action|
            <<~HTML
              <button class="btn-action" data-action="#{name}">#{action.description}</button>
            HTML
          end.join("\n")

          <<~HTML
            <div class="action-button-container">
                #{buttons}
            </div>
          HTML
        end

        def actionable_error?
          @error.respond_to?(:actionable?) && @error.actionable?
        end

        def render_backtrace
          return "" unless @error.backtrace

          application_trace = @error.backtrace.select { |line| !framework_line?(line) }
          framework_trace = @error.backtrace.select { |line| framework_line?(line) }

          <<~HTML
            <div class="error-section">
                <div class="tabs">
                    <button class="tab active" data-tab="application">Application Trace</button>
                    <button class="tab" data-tab="framework">Framework Trace</button>
                    <button class="tab" data-tab="full">Full Trace</button>
                </div>

                <div class="trace-list" id="application-trace">
                    #{render_trace_items(application_trace)}
                </div>

                <div class="trace-list" id="framework-trace" style="display: none;">
                    #{render_trace_items(framework_trace, framework: true)}
                </div>

                <div class="trace-list" id="full-trace" style="display: none;">
                    #{render_trace_items(@error.backtrace)}
                </div>
            </div>
          HTML
        end

        def render_trace_items(trace_lines, framework: false)
          trace_lines.map do |line|
            css_class = framework ? "trace-item trace-framework" : "trace-item"
            "<div class=\"#{css_class}\">#{escape_html(line)}</div>"
          end.join("\n")
        end

        def framework_line?(line)
          line.include?("/gems/") ||
            line.include?("hanami") ||
            line.include?("rack") ||
            line.include?("puma") ||
            line.include?("ruby/")
        end

        def render_request_info
          return "" unless request

          <<~HTML
            <div class="error-section">
                <h3>Request</h3>
                <div class="info-grid">
                    <div class="info-label">Method:</div>
                    <div class="info-value">#{request.request_method}</div>
                    <div class="info-label">Path:</div>
                    <div class="info-value">#{request.path_info}</div>
                    <div class="info-label">Query String:</div>
                    <div class="info-value">#{request.query_string.empty? ? "(none)" : request.query_string}</div>
                </div>
            </div>
          HTML
        end

        def render_environment_info
          <<~HTML
            <div class="error-section">
                <h3>Environment</h3>
                <div class="info-grid">
                    <div class="info-label">Hanami version:</div>
                    <div class="info-value">#{hanami_version}</div>
                    <div class="info-label">Ruby version:</div>
                    <div class="info-value">#{RUBY_VERSION} (#{RUBY_PLATFORM})</div>
                    <div class="info-label">Environment:</div>
                    <div class="info-value">#{ENV.fetch('HANAMI_ENV', 'development')}</div>
                </div>
            </div>
          HTML
        end

        def hanami_version
          return Hanami::VERSION if defined?(Hanami::VERSION)

          "Unknown"
        end

        def escape_html(text)
          text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
            .gsub("'", "&#39;")
        end

        def css_styles
          <<~CSS
            <style>
                :root {
                    --color-hanami-50: oklch(96.75% 0.016 8.28);
                    --color-hanami-100: oklch(94.38% 0.029 9.78);
                    --color-hanami-200: oklch(88.74% 0.061 9.53);
                    --color-hanami-300: oklch(83.17% 0.096 9.64);
                    --color-hanami-400: oklch(77.49% 0.136 9.92);
                    --color-hanami-500: oklch(71.93% 0.18 10.67);
                    --color-hanami-600: oklch(61.85% 0.247 12.28);
                    --color-hanami-700: oklch(49.89% 0.199 12.29);
                    --color-hanami-800: oklch(38.24% 0.153 12.34);
                    --color-hanami-900: oklch(26.33% 0.105 11.75);
                    --color-hanami-950: oklch(19.73% 0.079 11.46);
                }

                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }

                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
                    background: #f4f4f4;
                    color: #333;
                    line-height: 1.5;
                }

                @media (prefers-color-scheme: dark) {
                    body {
                        background: #1a1a1a;
                        color: #e4e4e4;
                    }
                }

                .error-header {
                    background: var(--color-hanami-700);
                    color: white;
                    padding: 25px 40px;
                }

                .error-header h1 {
                    font-size: 28px;
                    font-weight: 600;
                    margin: 0;
                    letter-spacing: -0.5px;
                }

                .error-container {
                    max-width: 1400px;
                    margin: 0 auto;
                    background: white;
                }

                @media (prefers-color-scheme: dark) {
                    .error-container {
                        background: #2d2d2d;
                    }
                }

                .error-message {
                    background: var(--color-hanami-50);
                    border-left: 5px solid var(--color-hanami-600);
                    padding: 30px 40px;
                }

                .error-message h2 {
                    font-size: 22px;
                    font-weight: 600;
                    color: var(--color-hanami-950);
                    margin-bottom: 15px;
                }

                @media (prefers-color-scheme: dark) {
                    .error-message {
                        background: var(--color-hanami-950);
                        border-left-color: var(--color-hanami-500);
                    }

                    .error-message h2 {
                        color: var(--color-hanami-100);
                    }
                }

                .action-button-container {
                    margin-top: 20px;
                }

                .btn-action {
                    background: var(--color-hanami-700);
                    color: white;
                    border: none;
                    padding: 12px 28px;
                    font-size: 15px;
                    font-weight: 500;
                    border-radius: 4px;
                    cursor: pointer;
                    transition: background 0.2s;
                    margin-right: 10px;
                    margin-bottom: 10px;
                }

                .btn-action:hover {
                    background: var(--color-hanami-800);
                }

                @media (prefers-color-scheme: dark) {
                    .btn-action {
                        background: var(--color-hanami-600);
                    }

                    .btn-action:hover {
                        background: var(--color-hanami-500);
                    }
                }

                .error-details {
                    padding: 40px;
                }

                .error-section {
                    margin-bottom: 40px;
                }

                .error-section h3 {
                    font-size: 16px;
                    font-weight: 600;
                    color: #555;
                    margin-bottom: 15px;
                    padding-bottom: 8px;
                    border-bottom: 1px solid #e0e0e0;
                }

                @media (prefers-color-scheme: dark) {
                    .error-section h3 {
                        color: #b0b0b0;
                        border-bottom-color: #404040;
                    }
                }

                .info-grid {
                    display: grid;
                    grid-template-columns: 150px 1fr;
                    gap: 12px 20px;
                    font-size: 14px;
                    background: #f9f9f9;
                    padding: 20px;
                    border-radius: 4px;
                }

                @media (prefers-color-scheme: dark) {
                    .info-grid {
                        background: #252525;
                    }
                }

                .info-label {
                    font-weight: 600;
                    color: #666;
                }

                @media (prefers-color-scheme: dark) {
                    .info-label {
                        color: #999;
                    }
                }

                .info-value {
                    color: #333;
                    font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
                    font-size: 13px;
                }

                @media (prefers-color-scheme: dark) {
                    .info-value {
                        color: #d0d0d0;
                    }
                }

                .trace-list {
                    background: #f9f9f9;
                    border: 1px solid #e0e0e0;
                    border-radius: 4px;
                    padding: 0;
                    margin: 15px 0;
                    max-height: 300px;
                    overflow-y: auto;
                }

                @media (prefers-color-scheme: dark) {
                    .trace-list {
                        background: #1e1e1e;
                        border-color: #404040;
                    }
                }

                .trace-item {
                    padding: 10px 15px;
                    border-bottom: 1px solid #e8e8e8;
                    font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
                    font-size: 12px;
                    color: #555;
                }

                @media (prefers-color-scheme: dark) {
                    .trace-item {
                        border-bottom-color: #353535;
                        color: #b0b0b0;
                    }
                }

                .trace-item:last-child {
                    border-bottom: none;
                }

                .trace-item:hover {
                    background: #f0f0f0;
                }

                @media (prefers-color-scheme: dark) {
                    .trace-item:hover {
                        background: #2a2a2a;
                    }
                }

                .trace-framework {
                    color: #999;
                }

                @media (prefers-color-scheme: dark) {
                    .trace-framework {
                        color: #666;
                    }
                }

                .tabs {
                    display: flex;
                    border-bottom: 2px solid #e0e0e0;
                    margin-bottom: 20px;
                }

                @media (prefers-color-scheme: dark) {
                    .tabs {
                        border-bottom-color: #404040;
                    }
                }

                .tab {
                    padding: 12px 24px;
                    background: transparent;
                    border: none;
                    font-size: 14px;
                    font-weight: 500;
                    color: #666;
                    cursor: pointer;
                    border-bottom: 3px solid transparent;
                    margin-bottom: -2px;
                }

                @media (prefers-color-scheme: dark) {
                    .tab {
                        color: #999;
                    }
                }

                .tab.active {
                    color: var(--color-hanami-700);
                    border-bottom-color: var(--color-hanami-700);
                }

                @media (prefers-color-scheme: dark) {
                    .tab.active {
                        color: var(--color-hanami-400);
                        border-bottom-color: var(--color-hanami-400);
                    }
                }

                .tab:hover {
                    color: #333;
                }

                @media (prefers-color-scheme: dark) {
                    .tab:hover {
                        color: #d0d0d0;
                    }
                }

                @media (max-width: 768px) {
                    .error-header,
                    .error-message,
                    .error-details {
                        padding: 20px;
                    }

                    .info-grid {
                        grid-template-columns: 1fr;
                        gap: 8px;
                    }

                    .error-header h1 {
                        font-size: 20px;
                    }
                }
            </style>
          CSS
        end

        def javascript
          <<~JS
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    // Tab switching functionality
                    const tabs = document.querySelectorAll('.tab');
                    const traceLists = document.querySelectorAll('.trace-list');

                    tabs.forEach(tab => {
                        tab.addEventListener('click', function() {
                            const targetTab = this.dataset.tab;
            #{'                '}
                            // Remove active class from all tabs
                            tabs.forEach(t => t.classList.remove('active'));
                            // Add active class to clicked tab
                            this.classList.add('active');
            #{'                '}
                            // Hide all trace lists
                            traceLists.forEach(list => list.style.display = 'none');
                            // Show target trace list
                            const targetList = document.getElementById(targetTab + '-trace');
                            if (targetList) {
                                targetList.style.display = 'block';
                            }
                        });
                    });

                    // Action button functionality
                    const actionButtons = document.querySelectorAll('.btn-action');
                    actionButtons.forEach(button => {
                        button.addEventListener('click', function() {
                            const actionName = this.dataset.action;
                            // In a real implementation, this would make an AJAX request
                            // to execute the action on the server
                            console.log('Executing action:', actionName);
                            alert('Action "' + actionName + '" would be executed here.');
                        });
                    });
                });
            </script>
          JS
        end
      end
    end
  end
end
