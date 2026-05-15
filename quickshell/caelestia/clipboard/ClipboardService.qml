pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    // ── Clipboard history items ───────────────────────────────────────────────
    property var items: []
    property bool loading: false
    property var firstSeenById: ({})

    // ── Pinned items ──────────────────────────────────────────────────────────
    property var pinnedItems: []
    property int pinnedRevision: 0

    // ── Image cache (LRU, max 50) ─────────────────────────────────────────────
    property var imageCache: ({})
    property var imageCacheOrder: []
    property int imageCacheRevision: 0
    readonly property int maxImageCacheSize: 50

    // ── Config shortcuts ──────────────────────────────────────────────────────
    readonly property int maxPinnedItems: 100
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/caelestia-clipboard"

    // ══════════════════════════════════════════════════════════════════════════
    // PERSISTENCE — pinned.json
    // ══════════════════════════════════════════════════════════════════════════

    FileView {
        id: pinnedFile
        path: root.configDir + "/pinned.json"
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.pinnedItems = data.items || [];
            } catch (_) {
                root.pinnedItems = [];
            }
            root.pinnedRevision++;
        }
        onLoadFailed: {
            root.pinnedItems = [];
            root.pinnedRevision++;
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CLIPHIST PROCESS CALLS
    // ══════════════════════════════════════════════════════════════════════════

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.loading = false;
                return;
            }
            const lines = listProc.stdout.text.split("\n").filter(l => l.trim().length > 0);
            const now = Date.now();
            const newItems = lines.map(line => {
                const tabIdx = line.indexOf("\t");
                const id = tabIdx >= 0 ? line.slice(0, tabIdx) : line;
                const preview = tabIdx >= 0 ? line.slice(tabIdx + 1) : "";
                const isImage = preview.startsWith("binary data image/");
                if (!root.firstSeenById[id]) {
                    root.firstSeenById[id] = now;
                }
                return { id, preview, isImage, mime: isImage ? "image/png" : "text/plain" };
            });
            root.items = newItems;
            root.loading = false;
        }
    }

    Process {
        id: copyProc
        property string pendingId: ""
        command: ["sh", "-c", `echo -n "${copyProc.pendingId}" | cliphist decode | wl-copy`]
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("ClipboardService: copy failed for id", copyProc.pendingId);
        }
    }

    Process {
        id: deleteProc
        property string pendingId: ""
        command: ["sh", "-c", `echo -n "${deleteProc.pendingId}" | cliphist delete`]
        onExited: exitCode => {
            if (exitCode === 0)
                root.list();
        }
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: exitCode => {
            if (exitCode === 0)
                root.list();
        }
    }

    // Image decode: cliphist decode <id> → base64 → data URL
    Process {
        id: imageDecodeProc
        property string pendingId: ""
        stdout: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0 || !imageDecodeProc.pendingId)
                return;
            const b64 = imageDecodeProc.stdout.text.replace(/\s/g, "");
            const dataUrl = "data:image/png;base64," + b64;
            const id = imageDecodeProc.pendingId;
            // LRU eviction
            if (!root.imageCache[id]) {
                if (root.imageCacheOrder.length >= root.maxImageCacheSize) {
                    const evict = root.imageCacheOrder.shift();
                    const copy = Object.assign({}, root.imageCache);
                    delete copy[evict];
                    root.imageCache = copy;
                }
                root.imageCacheOrder.push(id);
            }
            const updated = Object.assign({}, root.imageCache);
            updated[id] = dataUrl;
            root.imageCache = updated;
            root.imageCacheRevision++;
            imageDecodeProc.pendingId = "";
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // PUBLIC API
    // ══════════════════════════════════════════════════════════════════════════

    function list() {
        if (listProc.running)
            return;
        root.loading = true;
        listProc.running = true;
    }

    function copyItem(id) {
        if (copyProc.running)
            return;
        copyProc.pendingId = id;
        copyProc.running = true;
    }

    function deleteItem(id) {
        if (deleteProc.running)
            return;
        deleteProc.pendingId = id;
        deleteProc.running = true;
    }

    function wipeHistory() {
        if (!wipeProc.running)
            wipeProc.running = true;
    }

    function decodeImage(id) {
        if (imageDecodeProc.running || root.imageCache[id])
            return;
        imageDecodeProc.pendingId = id;
        imageDecodeProc.command = ["sh", "-c", `printf '%s' '${id}' | cliphist decode | base64 -w0`];
        imageDecodeProc.running = true;
    }

    // ── Pinned items ──────────────────────────────────────────────────────────

    function pinItem(id) {
        const item = root.items.find(i => i.id === id);
        if (!item)
            return;
        if (root.pinnedItems.length >= root.maxPinnedItems)
            return;
        if (root.pinnedItems.some(p => p.id === id))
            return;

        const pinned = {
            id: id,
            preview: item.preview,
            isImage: item.isImage,
            mime: item.mime,
            pinnedAt: Date.now()
        };
        // If image, store the data URL in the pinned entry
        if (item.isImage && root.imageCache[id]) {
            pinned.imageDataUrl = root.imageCache[id];
        }
        root.pinnedItems = [...root.pinnedItems, pinned];
        root.pinnedRevision++;
        savePinnedFile();
    }

    function unpinItem(id) {
        root.pinnedItems = root.pinnedItems.filter(p => p.id !== id);
        root.pinnedRevision++;
        savePinnedFile();
    }

    function copyPinnedItem(id) {
        const pinned = root.pinnedItems.find(p => p.id === id);
        if (!pinned)
            return;
        // Pinned items copy directly via their stored id
        copyItem(id);
    }

    function savePinnedFile() {
        const json = JSON.stringify({ items: root.pinnedItems });
        Quickshell.execDetached(["sh", "-c",
            `mkdir -p "${root.configDir}" && printf '%s' '${json.replace(/'/g, "'\\''")}' > "${root.configDir}/pinned.json"`
        ]);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // TYPE DETECTION
    // ══════════════════════════════════════════════════════════════════════════

    function getItemType(item) {
        if (!item)
            return "Text";
        if (item.isImage)
            return "Image";

        const preview = item.preview || "";
        const trimmed = preview.trim();

        // Color
        if (/^#[A-Fa-f0-9]{6}([A-Fa-f0-9]{2})?$/.test(trimmed)) return "Color";
        if (/^#[A-Fa-f0-9]{3}$/.test(trimmed))                    return "Color";
        if (/^[A-Fa-f0-9]{6}$/.test(trimmed))                     return "Color";
        if (/^rgba?\s*\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*[\d.]+\s*)?\)$/i.test(trimmed))
            return "Color";

        // Link
        if (/^https?:\/\//.test(trimmed)) return "Link";

        // Code — before File so `// comment` doesn't match `^/`
        if (/^(\/\/|\/\*|#!|\*|<!--)/.test(trimmed))              return "Code";
        if (/\b(function|import|export|const|let|var|class|def|return|if|else|for|while|async|await)\b/.test(preview))
            return "Code";
        if (/^[\{\[\(]/.test(trimmed))                             return "Code";

        // Emoji
        if (trimmed.length <= 4 && trimmed.length > 0 && trimmed.charCodeAt(0) > 255)
            return "Emoji";

        // File path
        if (/^file:\/\//.test(trimmed))  return "File";
        if (/^~\//.test(trimmed))        return "File";
        if ((/^\/[^\s/]/.test(trimmed) && !trimmed.includes(" ")) ||
            (/^\/[^\s]+\//.test(trimmed) && (trimmed.match(/\//g) || []).length >= 2))
            return "File";

        return "Text";
    }

    // ══════════════════════════════════════════════════════════════════════════
    // LIFECYCLE
    // ══════════════════════════════════════════════════════════════════════════

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.configDir]);
        Quickshell.execDetached(["sh", "-c",
            `[ -f "${root.configDir}/pinned.json" ] || echo '{"items":[]}' > "${root.configDir}/pinned.json"`
        ]);
        pinnedFile.reload();
        list();
    }
}
