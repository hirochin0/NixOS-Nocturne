{ pkgs, theme }:
pkgs.writeText "nocturne-wallpaper.rasi" ''
  * {
    font: "${theme.font} 11";
    background-color: transparent;
    text-color: #${theme.text};
    border-color: #${theme.accent};
  }
  window {
    width: 75%;
    location: center;
    anchor: center;
    background-color: #${theme.bg}f5;
    border: 2px;
    border-radius: ${toString theme.radius}px;
  }
  mainbox {
    children: [ inputbar, listview, message ];
    padding: 20px;
    spacing: 16px;
  }
  inputbar {
    children: [ prompt, entry ];
    background-color: #${theme.surface};
    border-radius: 10px;
    padding: 14px;
    spacing: 14px;
  }
  prompt { text-color: #${theme.cyan}; }
  entry { placeholder: "Search wallpapers..."; }
  listview {
    columns: 3;
    lines: 2;
    layout: vertical;
    flow: horizontal;
    fixed-height: true;
    dynamic: false;
    scrollbar: true;
    spacing: 12px;
  }
  element {
    children: [ element-icon, element-text ];
    orientation: vertical;
    padding: 10px;
    spacing: 8px;
    border: 2px;
    border-color: transparent;
    border-radius: 12px;
    background-color: #${theme.surface};
  }
  element selected {
    background-color: #${theme.elevated};
    border-color: #${theme.cyan};
  }
  element-icon {
    size: 240px;
    squared: false;
    horizontal-align: 0.5;
    vertical-align: 0.5;
  }
  element-text {
    horizontal-align: 0.5;
    vertical-align: 0.5;
  }
  message { padding: 4px; }
  textbox { text-color: #${theme.muted}; }
  scrollbar {
    handle-color: #${theme.accent};
    handle-width: 4px;
    padding: 0 0 0 8px;
  }
''
