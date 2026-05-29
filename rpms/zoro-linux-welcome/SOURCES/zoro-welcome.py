#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════
# zoro-welcome — Zoro Linux First-Run Welcome Application
# ═══════════════════════════════════════════════════════════════
# GTK4 welcome app shown on first login.
# Pages: Welcome, What's New, Enable Extras Repo, Themes, Docs
# ═══════════════════════════════════════════════════════════════

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gio, GLib
import subprocess
import os

APP_ID = "org.zorolinux.welcome"
APP_VERSION = "1.0.0"


class WelcomePage:
    """A single page in the welcome wizard."""
    def __init__(self, title, subtitle, body, icon_name=None, action=None, action_label=None):
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.icon_name = icon_name
        self.action = action
        self.action_label = action_label


# ── Page Definitions ─────────────────────────────────────────
PAGES = [
    WelcomePage(
        title="⚔  Welcome to Zoro Linux 10",
        subtitle="Santoryu Edition",
        body=(
            "Welcome, swordsman.\n\n"
            "Zoro Linux is a community-driven, enterprise-grade Linux distribution "
            "built for performance, reliability, and visual excellence.\n\n"
            "This quick tour will help you get started with your new system.\n\n"
            "\"I will be the world's greatest swordsman.\"\n"
            "— Roronoa Zoro"
        ),
        icon_name="zoro-linux",
    ),
    WelcomePage(
        title="What's New in Zoro Linux 10",
        subtitle="The Three Blades, Refined",
        body=(
            "🗡  Kernel 6.12 LTS — stability and performance\n"
            "🗡  DNF5 — lightning-fast package management\n"
            "🗡  GNOME 47 (ZoroDeck Shell) — custom desktop experience\n"
            "🗡  KDE Plasma 6 (ZoroBlade Shell) — alternative desktop\n"
            "🗡  zoro-fetch — beautiful system info on login\n"
            "🗡  10 original wallpapers — Zoro-themed artwork\n"
            "🗡  Security hardening — CIS/STIG profiles built-in\n"
            "🗡  Container-ready — Podman, Buildah, Skopeo\n\n"
            "All upstream branding has been replaced with "
            "original Zoro Linux identity."
        ),
        icon_name="emblem-new",
    ),
    WelcomePage(
        title="Enable Extra Repositories",
        subtitle="Unlock More Software",
        body=(
            "Zoro Linux ships with these repositories:\n\n"
            "✓  zoro-baseos — Core OS packages (enabled)\n"
            "✓  zoro-appstream — Applications (enabled)\n"
            "✓  zoro-extras — Community packages (enabled)\n"
            "○  zoro-crb — Development headers (disabled)\n"
            "○  zoro-dojo — Curated 3rd party apps (disabled)\n\n"
            "Would you like to enable the Extras repositories?\n"
            "You can also install EPEL for even more packages:\n"
            "  dnf install epel-release"
        ),
        icon_name="system-software-install",
        action="enable_extras",
        action_label="Enable Dojo Repository",
    ),
    WelcomePage(
        title="Choose Your Theme",
        subtitle="Light or Dark — The Blade Cuts Both Ways",
        body=(
            "Zoro Linux includes two GTK themes:\n\n"
            "🌑  ZoroDark — Dark mode, moonlit dojo aesthetic\n"
            "     Deep forest greens, blade silver accents\n\n"
            "☀  ZoroLight — Light mode, rice paper warmth\n"
            "     Clean surfaces, forest green highlights\n\n"
            "Both themes apply to GTK3, GTK4, and GNOME Shell.\n"
            "Change anytime in Settings → Appearance."
        ),
        icon_name="preferences-desktop-theme",
        action="open_themes",
        action_label="Open Theme Settings",
    ),
    WelcomePage(
        title="Documentation & Support",
        subtitle="The Dojo is Always Open",
        body=(
            "📖  Docs:      https://docs.zorolinux.org\n"
            "💬  Forums:    https://forums.zorolinux.org\n"
            "🐛  Bugs:      https://bugs.zorolinux.org\n"
            "📧  Email:     devel@zorolinux.org\n"
            "💻  Git:       https://git.zorolinux.org\n"
            "🔒  Security:  security@zorolinux.org\n\n"
            "Matrix:   #zorolinux:matrix.org\n"
            "IRC:      #zorolinux on Libera.Chat\n\n"
            "\"Nothing happened.\"\n"
            "— Roronoa Zoro\n\n"
            "Enjoy your new OS. Train hard. Cut deep."
        ),
        icon_name="help-about",
    ),
]


class ZoroWelcomeWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Welcome to Zoro Linux")
        self.set_default_size(700, 550)
        self.current_page = 0

        # Main layout
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_content(self.main_box)

        # Header bar
        header = Adw.HeaderBar()
        header.set_title_widget(Gtk.Label(label="⚔  Zoro Linux Welcome"))
        self.main_box.append(header)

        # Content area
        self.content_box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=16,
            margin_start=32,
            margin_end=32,
            margin_top=24,
            margin_bottom=16,
            vexpand=True,
        )
        self.main_box.append(self.content_box)

        # Title label
        self.title_label = Gtk.Label(
            halign=Gtk.Align.START,
            wrap=True,
        )
        self.title_label.add_css_class("title-1")
        self.content_box.append(self.title_label)

        # Subtitle label
        self.subtitle_label = Gtk.Label(
            halign=Gtk.Align.START,
        )
        self.subtitle_label.add_css_class("title-3")
        self.content_box.append(self.subtitle_label)

        # Separator
        self.content_box.append(Gtk.Separator())

        # Body text
        self.body_label = Gtk.Label(
            halign=Gtk.Align.START,
            valign=Gtk.Align.START,
            wrap=True,
            vexpand=True,
            selectable=True,
        )
        self.body_label.add_css_class("body")
        scroll = Gtk.ScrolledWindow(vexpand=True)
        scroll.set_child(self.body_label)
        self.content_box.append(scroll)

        # Action button (per-page)
        self.action_button = Gtk.Button()
        self.action_button.add_css_class("suggested-action")
        self.action_button.add_css_class("pill")
        self.action_button.set_visible(False)
        self.action_button.connect("clicked", self.on_action_clicked)
        self.content_box.append(self.action_button)

        # Navigation bar
        nav_box = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=12,
            margin_start=32,
            margin_end=32,
            margin_bottom=24,
        )
        self.main_box.append(nav_box)

        # Don't show again checkbox
        self.dont_show = Gtk.CheckButton(label="Don't show this again")
        nav_box.append(self.dont_show)

        # Spacer
        spacer = Gtk.Box(hexpand=True)
        nav_box.append(spacer)

        # Back button
        self.back_button = Gtk.Button(label="← Back")
        self.back_button.connect("clicked", self.on_back)
        nav_box.append(self.back_button)

        # Next/Finish button
        self.next_button = Gtk.Button(label="Next →")
        self.next_button.add_css_class("suggested-action")
        self.next_button.connect("clicked", self.on_next)
        nav_box.append(self.next_button)

        # Page indicator
        self.page_label = Gtk.Label()
        self.page_label.add_css_class("dim-label")
        nav_box.append(self.page_label)

        # Load first page
        self.load_page(0)

        # Apply custom CSS
        self.apply_css()

    def apply_css(self):
        css = b"""
        window {
            background-color: #0D1117;
        }
        .title-1 {
            color: #52B788;
        }
        .title-3 {
            color: #C9A84C;
        }
        .body {
            color: #F5F5F0;
            font-size: 14px;
            line-height: 1.6;
        }
        .suggested-action {
            background-color: #52B788;
            color: #0D1117;
            border-radius: 18px;
            padding: 8px 24px;
            font-weight: bold;
        }
        .suggested-action:hover {
            background-color: #2D6A4F;
            color: #F5F5F0;
        }
        headerbar {
            background-color: #1A3A2A;
            color: #F5F5F0;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def load_page(self, index):
        page = PAGES[index]
        self.current_page = index

        self.title_label.set_text(page.title)
        self.subtitle_label.set_text(page.subtitle)
        self.body_label.set_text(page.body)

        # Action button
        if page.action_label:
            self.action_button.set_label(page.action_label)
            self.action_button.set_visible(True)
        else:
            self.action_button.set_visible(False)

        # Navigation state
        self.back_button.set_sensitive(index > 0)

        if index == len(PAGES) - 1:
            self.next_button.set_label("Close ⚔")
        else:
            self.next_button.set_label("Next →")

        self.page_label.set_text(f"{index + 1} / {len(PAGES)}")

    def on_next(self, button):
        if self.current_page >= len(PAGES) - 1:
            # Save preference
            if self.dont_show.get_active():
                self.save_dont_show()
            self.close()
        else:
            self.load_page(self.current_page + 1)

    def on_back(self, button):
        if self.current_page > 0:
            self.load_page(self.current_page - 1)

    def on_action_clicked(self, button):
        page = PAGES[self.current_page]
        if page.action == "enable_extras":
            try:
                subprocess.run(
                    ["pkexec", "dnf", "config-manager", "--set-enabled", "zoro-dojo"],
                    check=False,
                )
                button.set_label("✓ Enabled!")
                button.set_sensitive(False)
            except Exception:
                button.set_label("Could not enable — try manually")
        elif page.action == "open_themes":
            try:
                subprocess.Popen(["gnome-control-center", "appearance"])
            except Exception:
                try:
                    subprocess.Popen(["systemsettings5"])
                except Exception:
                    pass

    def save_dont_show(self):
        """Save preference to not show welcome on next login."""
        autostart_dir = os.path.expanduser("~/.config/autostart")
        desktop_file = os.path.join(autostart_dir, "zoro-welcome.desktop")
        if os.path.exists(desktop_file):
            os.remove(desktop_file)
        # Also set GSettings if available
        try:
            settings = Gio.Settings.new("org.zorolinux.welcome")
            settings.set_boolean("show-on-startup", False)
        except Exception:
            pass


class ZoroWelcomeApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID)

    def do_activate(self):
        win = ZoroWelcomeWindow(self)
        win.present()


def main():
    app = ZoroWelcomeApp()
    return app.run(None)


if __name__ == "__main__":
    main()
