pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    // ── Visibility ────────────────────────────────────────────────────
    property bool panelOpen: false
    function toggle() { panelOpen = !panelOpen }
    function open()   { panelOpen = true }
    function close()  { panelOpen = false }

    // ── Tab state (0=History  1=Pinned  2=Notes) ──────────────────────
    property int activeTab: 0

    // ── Clipboard history ─────────────────────────────────────────────
    property var historyItems: []
    property string searchQuery: ""

    readonly property var filteredItems: {
        const q = searchQuery.trim().toLowerCase()
        if (q === "") return historyItems
        return historyItems.filter(i => i.text.toLowerCase().includes(q))
    }

    function refreshHistory() {
        historyProc.running = false
        historyProc.running = true
    }

    function itemType(text) {
        if (/^https?:\/\//i.test(text))      return "link"
        if (/^#[0-9a-f]{3,8}$/i.test(text)) return "color"
        if (text.startsWith("[[ binary"))    return "image"
        return "text"
    }

    Process {
        id: historyProc
        command: ["bash", "-c", "cliphist list"]
        running: false
        property var _buf: []

        stdout: SplitParser {
            onRead: function(line) {
                const tab = line.indexOf("\t")
                if (tab === -1) return
                const id   = line.substring(0, tab)
                const text = line.substring(tab + 1).trim()
                if (!text) return
                historyProc._buf.push({ id, text, type: root.itemType(text) })
            }
        }

        onRunningChanged: if (running) _buf = []
        onExited: root.historyItems = [..._buf]
    }

    Timer {
        interval: 3000
        running: root.panelOpen
        repeat: true
        onTriggered: root.refreshHistory()
    }

    onPanelOpenChanged: {
        if (panelOpen) refreshHistory()
        else searchQuery = ""
    }

    // ── Copy ──────────────────────────────────────────────────────────
    function copyItem(id) {
        _copyProc.itemId = id
        _copyProc.running = false
        _copyProc.running = true
    }

    Process {
        id: _copyProc
        property string itemId: ""
        command: ["bash", "-c", `cliphist decode '${_copyProc.itemId}' | wl-copy`]
        running: false
    }

    // ── Delete ────────────────────────────────────────────────────────
    function deleteItem(id) {
        _deleteProc.itemId = id
        _deleteProc.running = false
        _deleteProc.running = true
    }

    Process {
        id: _deleteProc
        property string itemId: ""
        command: ["bash", "-c", `printf '%s' '${_deleteProc.itemId}' | cliphist delete`]
        running: false
        onExited: root.refreshHistory()
    }

    // ── Pinned items ──────────────────────────────────────────────────
    property var pinnedItems: []

    function pinItem(item) {
        if (pinnedItems.some(p => p.id === item.id)) return
        pinnedItems = [...pinnedItems, Object.assign({}, item, { pinnedAt: Date.now() })]
        _savePinned()
    }

    function unpinItem(id) {
        pinnedItems = pinnedItems.filter(p => p.id !== id)
        _savePinned()
    }

    function isPinned(id) {
        return pinnedItems.some(p => p.id === id)
    }

    function _savePinned() {
        pinnedFile.setText(JSON.stringify(pinnedItems, null, 2))
    }

    FileView {
        id: pinnedFile
        path: `/home/hel/.local/state/qs-clipboard/pinned.json`
        onLoaded: {
            try { root.pinnedItems = JSON.parse(text()) ?? [] } catch(e) {}
        }
    }

    // ── NoteCards ─────────────────────────────────────────────────────
    property var noteCards: []

    // Accent colors pulled from M3 palette defaults — will auto-update with scheme
    readonly property var noteColors: [
        "#ffb0ca", // primary
        "#e2bdc7", // secondary
        "#f0bc95", // tertiary
        "#b3a2d5", // term4 purple
        "#B5CCBA", // success
        "#ffb4ab", // error
        "#88c0d0", // cool blue
        "#9e8c91"  // outline/muted
    ]

    function addNote(title) {
        const id = "note_" + Date.now()
        noteCards = [...noteCards, {
            id,
            title: title || "New note",
            content: "",
            color: noteColors[noteCards.length % noteColors.length],
            createdAt: Date.now()
        }]
        _saveNotes()
    }

    function updateNote(id, fields) {
        noteCards = noteCards.map(n => n.id === id ? Object.assign({}, n, fields) : n)
        _saveNotes()
    }

    function deleteNote(id) {
        noteCards = noteCards.filter(n => n.id !== id)
        _saveNotes()
    }

    function _saveNotes() {
        notesFile.setText(JSON.stringify(noteCards, null, 2))
    }

    FileView {
        id: notesFile
        path: `/home/hel/.local/state/qs-clipboard/notes.json`
        onLoaded: {
            try { root.noteCards = JSON.parse(text()) ?? [] } catch(e) {}
        }
    }

    // ── IPC ───────────────────────────────────────────────────────────
    // qs ipc -c caelestia call clipboard toggle
    // qs ipc -c caelestia call clipboard tab 1
    IpcHandler {
        target: "clipboard"
        function toggle() { root.toggle() }
        function open()   { root.open() }
        function close()  { root.close() }
        function tab(n)   { root.activeTab = parseInt(n) }
    }
}
