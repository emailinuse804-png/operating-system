#!/bin/bash
###############################################################################
# 05-ollama.sh - Install Ollama AI and SleekAI chat interface
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Setting up Ollama AI integration..."

# ─── Install Ollama binary ─────────────────────────────────────────────────
log_info "Creating Ollama installer script..."
cat > "${ROOTFS_DIR}/tmp/install-ollama.sh" << 'OLLAMAEOF'
#!/bin/bash
set -e

# Download and install Ollama
curl -fsSL https://ollama.ai/install.sh | sh || {
    echo "Ollama install script failed, trying direct download..."
    OLLAMA_VERSION="0.5.4"
    curl -fsSL -o /usr/local/bin/ollama \
        "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64"
    chmod +x /usr/local/bin/ollama
}
OLLAMAEOF
chmod +x "${ROOTFS_DIR}/tmp/install-ollama.sh"

# Run installer in chroot (may fail without network, so we make it non-fatal)
chroot "${ROOTFS_DIR}" bash -c '/tmp/install-ollama.sh' || {
    log_warn "Ollama could not be installed during build (network issue?)"
    log_info "Creating first-boot Ollama installer instead..."

    # Create a first-boot installer that runs when user first logs in
    cat > "${ROOTFS_DIR}/usr/local/bin/ollama-setup" << 'SETUPEOF'
#!/bin/bash
# First-boot Ollama installer
if ! command -v ollama &>/dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
    echo "Ollama installed! Pull a model with: ollama pull llama3.2"
fi
SETUPEOF
    chmod +x "${ROOTFS_DIR}/usr/local/bin/ollama-setup"
}

# ─── Ollama systemd service ────────────────────────────────────────────────
log_info "Creating Ollama systemd service..."
cat > "${ROOTFS_DIR}/etc/systemd/system/ollama.service" << 'EOF'
[Unit]
Description=Ollama AI Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="HOME=/var/lib/ollama"
Environment="OLLAMA_HOST=0.0.0.0:11434"

[Install]
WantedBy=multi-user.target
EOF

# Create ollama user and group
chroot "${ROOTFS_DIR}" bash -c '
    groupadd -f ollama 2>/dev/null || true
    useradd -r -g ollama -d /var/lib/ollama -s /usr/sbin/nologin ollama 2>/dev/null || true
    mkdir -p /var/lib/ollama
    chown -R ollama:ollama /var/lib/ollama
    systemctl enable ollama 2>/dev/null || true
'

# ─── SleekAI Chat Application ──────────────────────────────────────────────
log_info "Creating SleekAI chat application..."
cat > "${ROOTFS_DIR}/usr/local/bin/sleek-ai" << 'AIEOF'
#!/usr/bin/env python3
"""
SleekAI - Ollama Chat Interface for SleekOS
A modern, Windows-like AI assistant with a sleek dark UI.
"""

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.1')
from gi.repository import Gtk, WebKit2, GLib, Gdk
import json
import threading
import urllib.request
import subprocess
import os
import sys

OLLAMA_API = "http://localhost:11434"

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    :root {
        --bg-primary: #1a1a2e;
        --bg-secondary: #16213e;
        --bg-chat: #0f0f23;
        --accent: #60a5fa;
        --accent-hover: #93bbfc;
        --text-primary: #e2e8f0;
        --text-secondary: #94a3b8;
        --user-bg: #1e3a5f;
        --ai-bg: #1e1e3a;
        --border: #2d2d5e;
        --scrollbar: #334155;
        --input-bg: #1e293b;
    }

    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
        font-family: 'Noto Sans', 'Segoe UI', system-ui, sans-serif;
        background: var(--bg-primary);
        color: var(--text-primary);
        height: 100vh;
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }

    /* Header */
    .header {
        background: var(--bg-secondary);
        padding: 16px 24px;
        border-bottom: 1px solid var(--border);
        display: flex;
        align-items: center;
        gap: 12px;
        -webkit-app-region: drag;
    }

    .header-icon {
        width: 32px;
        height: 32px;
        background: linear-gradient(135deg, var(--accent), #a855f7);
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
    }

    .header-title {
        font-size: 16px;
        font-weight: 600;
    }

    .header-subtitle {
        font-size: 11px;
        color: var(--text-secondary);
    }

    .model-select {
        margin-left: auto;
        background: var(--input-bg);
        color: var(--text-primary);
        border: 1px solid var(--border);
        border-radius: 6px;
        padding: 6px 12px;
        font-size: 12px;
        -webkit-app-region: no-drag;
    }

    /* Chat Area */
    .chat-container {
        flex: 1;
        overflow-y: auto;
        padding: 20px 24px;
        background: var(--bg-chat);
        scroll-behavior: smooth;
    }

    .chat-container::-webkit-scrollbar { width: 6px; }
    .chat-container::-webkit-scrollbar-track { background: transparent; }
    .chat-container::-webkit-scrollbar-thumb {
        background: var(--scrollbar);
        border-radius: 3px;
    }

    .message {
        margin-bottom: 16px;
        display: flex;
        gap: 12px;
        animation: fadeIn 0.3s ease;
    }

    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(8px); }
        to { opacity: 1; transform: translateY(0); }
    }

    .message-avatar {
        width: 36px;
        height: 36px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 16px;
        flex-shrink: 0;
    }

    .message.user .message-avatar {
        background: var(--user-bg);
    }

    .message.ai .message-avatar {
        background: linear-gradient(135deg, var(--accent), #a855f7);
    }

    .message-content {
        flex: 1;
        padding: 12px 16px;
        border-radius: 12px;
        font-size: 14px;
        line-height: 1.6;
        max-width: 80%;
    }

    .message.user .message-content {
        background: var(--user-bg);
        border-bottom-left-radius: 4px;
    }

    .message.ai .message-content {
        background: var(--ai-bg);
        border-bottom-left-radius: 4px;
    }

    .message-content pre {
        background: #0d1117;
        padding: 12px;
        border-radius: 8px;
        overflow-x: auto;
        margin: 8px 0;
        font-size: 13px;
    }

    .message-content code {
        background: #0d1117;
        padding: 2px 6px;
        border-radius: 4px;
        font-size: 13px;
    }

    .typing-indicator {
        display: inline-flex;
        gap: 4px;
        padding: 4px 0;
    }

    .typing-indicator span {
        width: 8px;
        height: 8px;
        background: var(--accent);
        border-radius: 50%;
        animation: typing 1.4s infinite;
    }

    .typing-indicator span:nth-child(2) { animation-delay: 0.2s; }
    .typing-indicator span:nth-child(3) { animation-delay: 0.4s; }

    @keyframes typing {
        0%, 60%, 100% { transform: translateY(0); opacity: 0.4; }
        30% { transform: translateY(-8px); opacity: 1; }
    }

    /* Welcome Screen */
    .welcome {
        text-align: center;
        padding: 60px 24px;
        color: var(--text-secondary);
    }

    .welcome h2 {
        font-size: 24px;
        color: var(--text-primary);
        margin-bottom: 8px;
    }

    .welcome p {
        font-size: 14px;
        margin-bottom: 24px;
    }

    .suggestions {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        justify-content: center;
    }

    .suggestion {
        background: var(--input-bg);
        border: 1px solid var(--border);
        border-radius: 8px;
        padding: 10px 16px;
        cursor: pointer;
        font-size: 13px;
        color: var(--text-secondary);
        transition: all 0.2s;
    }

    .suggestion:hover {
        border-color: var(--accent);
        color: var(--accent);
    }

    /* Input Area */
    .input-area {
        background: var(--bg-secondary);
        padding: 16px 24px;
        border-top: 1px solid var(--border);
        display: flex;
        gap: 12px;
        align-items: flex-end;
    }

    .input-wrapper {
        flex: 1;
        position: relative;
    }

    #message-input {
        width: 100%;
        background: var(--input-bg);
        color: var(--text-primary);
        border: 1px solid var(--border);
        border-radius: 12px;
        padding: 12px 16px;
        font-size: 14px;
        font-family: inherit;
        resize: none;
        outline: none;
        max-height: 120px;
        min-height: 44px;
        transition: border-color 0.2s;
    }

    #message-input:focus {
        border-color: var(--accent);
    }

    #message-input::placeholder {
        color: var(--text-secondary);
    }

    .send-btn {
        background: var(--accent);
        color: #0f172a;
        border: none;
        border-radius: 10px;
        width: 44px;
        height: 44px;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
        transition: all 0.2s;
    }

    .send-btn:hover {
        background: var(--accent-hover);
        transform: scale(1.05);
    }

    .send-btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
        transform: none;
    }

    /* Status bar */
    .status-bar {
        background: var(--bg-secondary);
        padding: 4px 24px;
        font-size: 11px;
        color: var(--text-secondary);
        border-top: 1px solid var(--border);
        display: flex;
        justify-content: space-between;
    }

    .status-dot {
        display: inline-block;
        width: 6px;
        height: 6px;
        border-radius: 50%;
        margin-right: 6px;
    }

    .status-dot.online { background: #22c55e; }
    .status-dot.offline { background: #ef4444; }
</style>
</head>
<body>
    <div class="header">
        <div class="header-icon">🧠</div>
        <div>
            <div class="header-title">SleekAI Assistant</div>
            <div class="header-subtitle">Powered by Ollama</div>
        </div>
        <select class="model-select" id="model-select" onchange="changeModel()">
            <option value="llama3.2">llama3.2</option>
        </select>
    </div>

    <div class="chat-container" id="chat">
        <div class="welcome" id="welcome">
            <h2>👋 Hello! I'm SleekAI</h2>
            <p>Your local AI assistant. Ask me anything!</p>
            <div class="suggestions">
                <div class="suggestion" onclick="sendSuggestion('Explain quantum computing simply')">Explain quantum computing</div>
                <div class="suggestion" onclick="sendSuggestion('Write a Python hello world')">Write Python code</div>
                <div class="suggestion" onclick="sendSuggestion('What can you help me with?')">What can you do?</div>
                <div class="suggestion" onclick="sendSuggestion('Tell me a fun fact')">Fun fact</div>
            </div>
        </div>
    </div>

    <div class="input-area">
        <div class="input-wrapper">
            <textarea id="message-input"
                      placeholder="Type a message... (Enter to send, Shift+Enter for newline)"
                      rows="1"
                      onkeydown="handleKey(event)"
                      oninput="autoResize(this)"></textarea>
        </div>
        <button class="send-btn" id="send-btn" onclick="sendMessage()">➤</button>
    </div>

    <div class="status-bar">
        <span><span class="status-dot" id="status-dot"></span><span id="status-text">Checking...</span></span>
        <span id="model-info"></span>
    </div>

<script>
    let currentModel = 'llama3.2';
    let isGenerating = false;
    let conversationHistory = [];

    // Check Ollama connection
    async function checkConnection() {
        try {
            const res = await fetch('OLLAMA_API_URL/api/tags');
            const data = await res.json();
            document.getElementById('status-dot').className = 'status-dot online';
            document.getElementById('status-text').textContent = 'Connected to Ollama';

            // Populate model list
            const select = document.getElementById('model-select');
            select.innerHTML = '';
            if (data.models && data.models.length > 0) {
                data.models.forEach(m => {
                    const opt = document.createElement('option');
                    opt.value = m.name;
                    opt.textContent = m.name;
                    select.appendChild(opt);
                });
                currentModel = data.models[0].name;
                document.getElementById('model-info').textContent = 'Model: ' + currentModel;
            } else {
                const opt = document.createElement('option');
                opt.value = '';
                opt.textContent = 'No models (run: ollama pull llama3.2)';
                select.appendChild(opt);
                document.getElementById('model-info').textContent = 'No models available';
            }
        } catch(e) {
            document.getElementById('status-dot').className = 'status-dot offline';
            document.getElementById('status-text').textContent = 'Ollama not running';
            document.getElementById('model-info').textContent = 'Start with: systemctl start ollama';
        }
    }

    function changeModel() {
        currentModel = document.getElementById('model-select').value;
        document.getElementById('model-info').textContent = 'Model: ' + currentModel;
    }

    function autoResize(el) {
        el.style.height = 'auto';
        el.style.height = Math.min(el.scrollHeight, 120) + 'px';
    }

    function handleKey(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    }

    function sendSuggestion(text) {
        document.getElementById('message-input').value = text;
        sendMessage();
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    function formatMessage(text) {
        // Basic markdown-like formatting
        text = escapeHtml(text);
        // Code blocks
        text = text.replace(/```(\\w*)\\n([\\s\\S]*?)```/g, '<pre><code>$2</code></pre>');
        // Inline code
        text = text.replace(/`([^`]+)`/g, '<code>$1</code>');
        // Bold
        text = text.replace(/\\*\\*(.+?)\\*\\*/g, '<strong>$1</strong>');
        // Newlines
        text = text.replace(/\\n/g, '<br>');
        return text;
    }

    function addMessage(role, content) {
        const welcome = document.getElementById('welcome');
        if (welcome) welcome.remove();

        const chat = document.getElementById('chat');
        const msg = document.createElement('div');
        msg.className = 'message ' + (role === 'user' ? 'user' : 'ai');

        const avatar = role === 'user' ? '👤' : '🧠';
        msg.innerHTML = `
            <div class="message-avatar">${avatar}</div>
            <div class="message-content">${formatMessage(content)}</div>
        `;

        chat.appendChild(msg);
        chat.scrollTop = chat.scrollHeight;
        return msg;
    }

    function addTypingIndicator() {
        const welcome = document.getElementById('welcome');
        if (welcome) welcome.remove();

        const chat = document.getElementById('chat');
        const msg = document.createElement('div');
        msg.className = 'message ai';
        msg.id = 'typing';
        msg.innerHTML = `
            <div class="message-avatar">🧠</div>
            <div class="message-content">
                <div class="typing-indicator">
                    <span></span><span></span><span></span>
                </div>
            </div>
        `;
        chat.appendChild(msg);
        chat.scrollTop = chat.scrollHeight;
    }

    function removeTypingIndicator() {
        const el = document.getElementById('typing');
        if (el) el.remove();
    }

    async function sendMessage() {
        if (isGenerating) return;

        const input = document.getElementById('message-input');
        const text = input.value.trim();
        if (!text || !currentModel) return;

        input.value = '';
        input.style.height = 'auto';
        isGenerating = true;
        document.getElementById('send-btn').disabled = true;

        addMessage('user', text);
        conversationHistory.push({ role: 'user', content: text });

        addTypingIndicator();

        try {
            const response = await fetch('OLLAMA_API_URL/api/chat', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: currentModel,
                    messages: conversationHistory,
                    stream: false
                })
            });

            const data = await response.json();
            removeTypingIndicator();

            const aiContent = data.message?.content || 'No response received.';
            addMessage('ai', aiContent);
            conversationHistory.push({ role: 'assistant', content: aiContent });

        } catch(e) {
            removeTypingIndicator();
            addMessage('ai', '⚠️ Error: Could not connect to Ollama. Make sure the service is running: `sudo systemctl start ollama`');
        }

        isGenerating = false;
        document.getElementById('send-btn').disabled = false;
        input.focus();
    }

    // Initialize
    checkConnection();
    setInterval(checkConnection, 30000);
    document.getElementById('message-input').focus();
</script>
</body>
</html>
""".replace('OLLAMA_API_URL', OLLAMA_API)


class SleekAIWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="SleekAI Assistant")
        self.set_default_size(800, 700)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Set dark theme
        settings = Gtk.Settings.get_default()
        settings.set_property("gtk-application-prefer-dark-theme", True)

        # Header bar
        header = Gtk.HeaderBar()
        header.set_show_close_button(True)
        header.set_title("SleekAI Assistant")
        header.set_subtitle("Powered by Ollama")
        self.set_titlebar(header)

        # Setup Ollama button
        setup_btn = Gtk.Button(label="Setup Ollama")
        setup_btn.connect("clicked", self.setup_ollama)
        header.pack_end(setup_btn)

        # WebKit view
        self.webview = WebKit2.WebView()
        settings = self.webview.get_settings()
        settings.set_enable_javascript(True)
        settings.set_javascript_can_access_clipboard(True)
        settings.set_enable_developer_extras(False)

        # Allow local API access
        self.webview.load_html(HTML_TEMPLATE, "file:///")

        scrolled = Gtk.ScrolledWindow()
        scrolled.add(self.webview)

        self.add(scrolled)

    def setup_ollama(self, widget):
        """Launch terminal to set up Ollama"""
        subprocess.Popen([
            'sakura', '-e', 'bash', '-c',
            'echo "=== Ollama Setup ===" && '
            'echo "" && '
            'if ! command -v ollama &>/dev/null; then '
            '    echo "Installing Ollama..." && '
            '    curl -fsSL https://ollama.ai/install.sh | sh; '
            'fi && '
            'echo "" && '
            'echo "Starting Ollama service..." && '
            'sudo systemctl start ollama && '
            'sleep 2 && '
            'echo "" && '
            'echo "Pulling default model (llama3.2)..." && '
            'ollama pull llama3.2 && '
            'echo "" && '
            'echo "✅ Setup complete! You can now use SleekAI." && '
            'echo "Press Enter to close..." && '
            'read'
        ])


def main():
    # Check if we should run setup first
    if '--setup' in sys.argv:
        os.system('sakura -e bash -c "curl -fsSL https://ollama.ai/install.sh | sh && ollama pull llama3.2"')
        return

    win = SleekAIWindow()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
AIEOF
chmod +x "${ROOTFS_DIR}/usr/local/bin/sleek-ai"

# ─── Ollama helper commands ────────────────────────────────────────────────
log_info "Creating Ollama helper scripts..."

cat > "${ROOTFS_DIR}/usr/local/bin/ollama-models" << 'EOF'
#!/bin/bash
# List and manage Ollama models
echo "╔══════════════════════════════════════╗"
echo "║     Ollama Model Manager             ║"
echo "╚══════════════════════════════════════╝"
echo ""

if ! command -v ollama &>/dev/null; then
    echo "Ollama is not installed. Run: ollama-setup"
    exit 1
fi

echo "Installed models:"
ollama list 2>/dev/null || echo "  (none)"
echo ""
echo "Popular models to install:"
echo "  ollama pull llama3.2        (3B - General purpose)"
echo "  ollama pull llama3.2:1b     (1B - Lightweight)"
echo "  ollama pull codellama       (7B - Code generation)"
echo "  ollama pull mistral         (7B - Fast & capable)"
echo "  ollama pull phi3            (3.8B - Microsoft)"
echo ""
read -p "Enter model to pull (or 'q' to quit): " model
if [[ "$model" != "q" && -n "$model" ]]; then
    ollama pull "$model"
fi
EOF
chmod +x "${ROOTFS_DIR}/usr/local/bin/ollama-models"

log_success "Ollama AI integration configured"
