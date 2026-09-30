# -*- coding: utf-8 -*-
import asyncio
import queue
import threading
from collections.abc import Awaitable
from datetime import datetime
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from typing import Callable

from main import ImportResult, import_jsonl_data, test_connection
from shared.configuration.provider import ConfigProvider
from shared.configuration.user_config import (
    CONFIG_PATH,
    DatabaseConfig,
    GatewayConfig,
    RunStatistics,
    load_user_config,
    save_user_config,
)


class GatewayApp:
    BACKGROUND = "#f3f4f1"
    SURFACE = "#ffffff"
    SIDEBAR = "#29343a"
    INK = "#2c3539"
    MUTED = "#788187"
    LINE = "#dfe3e2"
    ACCENT = "#c5d4cb"
    GREEN = "#58776a"
    RED = "#a85f5b"
    FONT = "Segoe UI"

    STEPS = (
        ("Источник данных", "Укажите JSONL-файл, созданный модом Factorio."),
        ("Назначение данных", "Заказы и события будут записаны в PostgreSQL."),
        ("Подключение", "Введите реквизиты целевой базы данных."),
        ("Проверка и сохранение", "Проверим доступ к базе и сохраним настройки."),
    )

    def __init__(self) -> None:
        self.root = tk.Tk()
        self.root.title("LTN Analytics Gateway")
        self.root.geometry("960x640")
        self.root.minsize(860, 570)
        self.root.configure(bg=self.BACKGROUND)
        self._configure_styles()

        self.result_queue: queue.Queue[tuple] = queue.Queue()
        self.busy_buttons: list[tk.Button] = []
        self.dashboard_status: tk.Label | None = None
        self.settings_status: tk.Label | None = None
        self.load_error: str | None = None
        try:
            self.config = load_user_config()
        except Exception as error:
            self.config = None
            self.load_error = f"Файл настроек не прочитан: {error}"

        self._start_polling()
        if self.config is None:
            self.config = GatewayConfig()
            self.show_wizard()
        else:
            self.show_dashboard()

    def _configure_styles(self) -> None:
        style = ttk.Style(self.root)
        style.theme_use("clam")
        style.configure("Gateway.TCombobox", padding=8, font=(self.FONT, 11))

    def run(self) -> None:
        self.root.mainloop()

    def _clear_window(self) -> None:
        for child in self.root.winfo_children():
            child.destroy()
        self.busy_buttons = []

    def _start_polling(self) -> None:
        self.root.after(120, self._poll_results)

    def _poll_results(self) -> None:
        try:
            while True:
                result = self.result_queue.get_nowait()
                if result[0] == "error":
                    self._set_busy(False)
                    self._show_error(result[1])
                else:
                    self._set_busy(False)
                    result[2](result[1])
        except queue.Empty:
            pass
        self.root.after(120, self._poll_results)

    def _run_async(
        self,
        operation: Callable[[], Awaitable[object]],
        on_success: Callable[[object], None],
    ) -> None:
        self._set_busy(True)

        def worker() -> None:
            try:
                result = asyncio.run(operation())
            except Exception as error:
                self.result_queue.put(("error", str(error)))
            else:
                self.result_queue.put(("success", result, on_success))

        threading.Thread(target=worker, daemon=True).start()

    def _set_busy(self, busy: bool) -> None:
        for button in self.busy_buttons:
            button.configure(state="disabled" if busy else "normal")

    def _show_error(self, details: str) -> None:
        if self.dashboard_status and self.dashboard_status.winfo_exists():
            self.dashboard_status.configure(
                text=f"Не удалось выполнить операцию: {details}",
                fg=self.RED,
            )
        elif self.settings_status and self.settings_status.winfo_exists():
            self.settings_status.configure(text=details, fg=self.RED)
        elif self.wizard_status and self.wizard_status.winfo_exists():
            self.wizard_status.configure(text=details, fg=self.RED)
        else:
            messagebox.showerror("Не удалось выполнить операцию", details, parent=self.root)

    def _button(
        self,
        parent: tk.Misc,
        text: str,
        command: Callable[[], None],
        primary: bool = False,
        **options: object,
    ) -> tk.Button:
        background = self.INK if primary else self.SURFACE
        foreground = "#ffffff" if primary else self.INK
        button = tk.Button(
            parent,
            text=text,
            command=command,
            bg=background,
            fg=foreground,
            activebackground=self.GREEN if primary else "#e9eee7",
            activeforeground="#ffffff" if primary else self.INK,
            disabledforeground="#89938d",
            relief="flat",
            bd=0,
            padx=18,
            pady=11,
            font=(self.FONT, 10, "bold"),
            cursor="hand2",
            **options,
        )
        return button

    def _label(
        self,
        parent: tk.Misc,
        text: str,
        *,
        size: int = 10,
        color: str | None = None,
        weight: str = "normal",
        **options: object,
    ) -> tk.Label:
        return tk.Label(
            parent,
            text=text,
            bg=options.pop("bg", self.SURFACE),
            fg=color or self.INK,
            font=(self.FONT, size, weight),
            anchor=options.pop("anchor", "w"),
            **options,
        )

    def _entry(
        self,
        parent: tk.Misc,
        caption: str,
        variable: tk.StringVar,
        *,
        show: str | None = None,
        reveal_toggle: bool = False,
    ) -> tk.Frame:
        frame = tk.Frame(parent, bg=self.SURFACE)
        self._label(frame, caption, size=9, color=self.MUTED, weight="bold").pack(
            anchor="w", pady=(0, 7)
        )
        entry = tk.Entry(
            frame,
            textvariable=variable,
            show=show or "",
            relief="flat",
            bg="#f6f7f6",
            fg=self.INK,
            insertbackground=self.INK,
            font=(self.FONT, 11),
            highlightthickness=1,
            highlightbackground=self.LINE,
            highlightcolor=self.GREEN,
        )
        reveal_button: tk.Button | None = None
        if reveal_toggle:
            field_row = tk.Frame(frame, bg=self.SURFACE)
            field_row.pack(fill="x")
            entry.pack(in_=field_row, side="left", fill="x", expand=True, ipady=10)

            def toggle_password() -> None:
                if entry.cget("show"):
                    entry.configure(show="")
                    reveal_button.configure(text="Скрыть")
                else:
                    entry.configure(show=show or "●")
                    reveal_button.configure(text="Показать")

            reveal_button = self._button(
                field_row,
                "Показать",
                toggle_password,
            )
            reveal_button.configure(padx=12, pady=8)
            reveal_button.pack(side="right", padx=(8, 0))
        else:
            entry.pack(fill="x", ipady=10)
        self._bind_entry_clipboard(entry)
        return frame

    def _bind_entry_clipboard(self, entry: tk.Entry) -> None:
        entry.bind("<Control-KeyPress>", self._entry_control_shortcut)
        entry.bind(
            "<Shift-Insert>",
            lambda event: self._entry_shortcut(event, "paste"),
        )
        entry.bind(
            "<Control-Insert>",
            lambda event: self._entry_shortcut(event, "copy"),
        )
        entry.bind("<<Paste>>", lambda event: self._entry_shortcut(event, "paste"))
        entry.bind("<<Copy>>", lambda event: self._entry_shortcut(event, "copy"))
        entry.bind("<<Cut>>", lambda event: self._entry_shortcut(event, "cut"))

        context_menu = tk.Menu(entry, tearoff=False)
        context_menu.add_command(
            label="Вырезать",
            command=lambda: self._entry_clipboard_action(entry, "cut"),
        )
        context_menu.add_command(
            label="Копировать",
            command=lambda: self._entry_clipboard_action(entry, "copy"),
        )
        context_menu.add_command(
            label="Вставить",
            command=lambda: self._entry_clipboard_action(entry, "paste"),
        )
        context_menu.add_separator()
        context_menu.add_command(
            label="Выделить всё",
            command=lambda: entry.select_range(0, "end"),
        )

        def show_context_menu(event: tk.Event) -> str:
            entry.focus_set()
            context_menu.tk_popup(event.x_root, event.y_root)
            context_menu.grab_release()
            return "break"

        entry.bind("<Button-3>", show_context_menu)

    @staticmethod
    def _entry_shortcut(event: tk.Event, action: str) -> str:
        widget = event.widget
        if action == "select-all":
            widget.select_range(0, "end")
            widget.icursor("end")
        else:
            GatewayApp._entry_clipboard_action(widget, action)
        return "break"

    @staticmethod
    def _entry_control_shortcut(event: tk.Event) -> str | None:
        keysym = event.keysym.lower()
        action_by_keysym = {
            "c": "copy",
            "cyrillic_es": "copy",
            "с": "copy",
            "v": "paste",
            "cyrillic_em": "paste",
            "м": "paste",
            "x": "cut",
            "ч": "cut",
            "a": "select-all",
            "ф": "select-all",
        }
        action_by_keycode = {
            65: "select-all",
            67: "copy",
            86: "paste",
            88: "cut",
        }
        action = action_by_keysym.get(keysym) or action_by_keycode.get(event.keycode)
        if action is None:
            return None
        return GatewayApp._entry_shortcut(event, action)

    @staticmethod
    def _entry_clipboard_action(entry: tk.Entry, action: str) -> None:
        try:
            selection_start = entry.index("sel.first")
            selection_end = entry.index("sel.last")
        except tk.TclError:
            selection_start = selection_end = entry.index("insert")

        if action == "copy" or action == "cut":
            if not entry.selection_present():
                return
            selected_text = entry.get()[selection_start:selection_end]
            entry.clipboard_clear()
            entry.clipboard_append(selected_text)
            if action == "cut":
                entry.delete(selection_start, selection_end)
                entry.icursor(selection_start)
            return

        if action == "paste":
            try:
                pasted_text = entry.clipboard_get()
            except tk.TclError:
                return
            entry.delete(selection_start, selection_end)
            entry.insert(selection_start, pasted_text)
            entry.icursor(selection_start + len(pasted_text))

    def show_wizard(self) -> None:
        self._clear_window()
        self.root.configure(bg=self.BACKGROUND)
        self.wizard_step = 0
        current = self.config
        self.source_var = tk.StringVar(value=current.source_jsonl_path)
        self.host_var = tk.StringVar(value=current.database.db_host)
        self.port_var = tk.StringVar(value=str(current.database.db_port))
        self.database_var = tk.StringVar(value=current.database.db_name)
        self.user_var = tk.StringVar(value=current.database.db_user)
        self.password_var = tk.StringVar(value=current.database.db_password)
        self.ssl_var = tk.BooleanVar(value=current.database.db_ssl)
        self.wizard_status: tk.Label | None = None
        self._render_wizard_step()

    def _render_wizard_step(self) -> None:
        self._clear_window()
        shell = tk.Frame(self.root, bg=self.BACKGROUND)
        shell.pack(fill="both", expand=True, padx=42, pady=26)

        masthead = tk.Frame(shell, bg=self.BACKGROUND)
        masthead.pack(fill="x", pady=(0, 20))
        self._label(
            masthead,
            "LTN ANALYTICS  /  GATEWAY",
            size=10,
            color=self.GREEN,
            weight="bold",
            bg=self.BACKGROUND,
        ).pack(side="left")
        self._label(
            masthead,
            "ПЕРВИЧНАЯ НАСТРОЙКА",
            size=9,
            color=self.MUTED,
            weight="bold",
            bg=self.BACKGROUND,
        ).pack(side="right")

        self._label(
            shell,
            self.STEPS[self.wizard_step][0],
            size=27,
            weight="bold",
            bg=self.BACKGROUND,
        ).pack(anchor="w")
        self._label(
            shell,
            f"Шаг {self.wizard_step + 1} из 4  ·  {self.STEPS[self.wizard_step][1]}",
            size=11,
            color=self.MUTED,
            bg=self.BACKGROUND,
        ).pack(anchor="w", pady=(6, 16))

        progress = tk.Frame(shell, bg=self.BACKGROUND)
        progress.pack(fill="x", pady=(0, 18))
        for index, (title, _) in enumerate(self.STEPS):
            segment = tk.Frame(
                progress,
                bg=self.GREEN if index <= self.wizard_step else self.LINE,
                height=4,
            )
            segment.pack(side="left", fill="x", expand=True, padx=(0 if index == 0 else 6, 0))
            segment.pack_propagate(False)

        content = tk.Frame(
            shell,
            bg=self.SURFACE,
            highlightthickness=1,
            highlightbackground=self.LINE,
        )
        content.pack(fill="both", expand=True)
        body = tk.Frame(content, bg=self.SURFACE)
        body.pack(fill="both", expand=True, padx=28, pady=22)
        self._render_wizard_content(body)

        footer = tk.Frame(shell, bg=self.BACKGROUND)
        footer.pack(fill="x", pady=(14, 0))
        self.wizard_status = self._label(
            footer,
            self.load_error or "",
            size=9,
            color=self.RED if self.load_error else self.MUTED,
            bg=self.BACKGROUND,
        )
        self.wizard_status.pack(side="left")

        if self.wizard_step > 0:
            back = self._button(footer, "Назад", self._previous_step)
            back.pack(side="right", padx=(8, 0))
            self.busy_buttons.append(back)
        if self.wizard_step < 3:
            next_button = self._button(
                footer,
                "Далее  →",
                self._next_step,
                primary=True,
            )
            next_button.pack(side="right")
        else:
            save_button = self._button(
                footer,
                "Проверить и сохранить",
                self._check_and_save,
                primary=True,
            )
            save_button.pack(side="right")
            self.busy_buttons.append(save_button)

    def _render_wizard_content(self, parent: tk.Frame) -> None:
        if self.wizard_step == 0:
            self._label(parent, "Файл снимков Factorio", size=16, weight="bold").pack(
                anchor="w", pady=(2, 8)
            )
            self._label(
                parent,
                "JSONL-файл, который мод записывает в script-output.",
                size=10,
                color=self.MUTED,
            ).pack(anchor="w", pady=(0, 22))
            row = tk.Frame(parent, bg=self.SURFACE)
            row.pack(fill="x")
            path_entry = tk.Entry(
                row,
                textvariable=self.source_var,
                relief="flat",
                bg="#f6f7f6",
                fg=self.INK,
                font=(self.FONT, 10),
                highlightthickness=1,
                highlightbackground=self.LINE,
            )
            path_entry.pack(side="left", fill="x", expand=True, ipady=12)
            self._bind_entry_clipboard(path_entry)
            browse = self._button(row, "Обзор…", self._browse_source)
            browse.pack(side="left", padx=(10, 0))
        elif self.wizard_step == 1:
            self._label(parent, "Куда загружать данные", size=16, weight="bold").pack(
                anchor="w", pady=(2, 8)
            )
            self._label(
                parent,
                "Доступное назначение",
                size=9,
                color=self.MUTED,
                weight="bold",
            ).pack(anchor="w", pady=(12, 8))
            destination = tk.Frame(
                parent,
                bg="#f6f7f6",
                highlightthickness=1,
                highlightbackground=self.GREEN,
            )
            destination.pack(fill="x")
            self._label(destination, "01", size=11, color=self.GREEN, weight="bold", bg="#f6f7f6").pack(
                side="left", padx=18, pady=20
            )
            details = tk.Frame(destination, bg="#f6f7f6")
            details.pack(side="left", fill="x", expand=True, pady=16)
            self._label(details, "PostgreSQL", size=14, weight="bold", bg="#f6f7f6").pack(
                anchor="w"
            )
            self._label(
                details,
                "Таблицы orders и order_events",
                size=10,
                color=self.MUTED,
                bg="#f6f7f6",
            ).pack(anchor="w", pady=(4, 0))
            self._label(
                parent,
                "Записи с уже существующими идентификаторами будут пропущены.",
                size=10,
                color=self.MUTED,
            ).pack(anchor="w", pady=(16, 0))
        elif self.wizard_step == 2:
            self._label(parent, "Реквизиты PostgreSQL", size=16, weight="bold").pack(
                anchor="w", pady=(2, 22)
            )
            grid = tk.Frame(parent, bg=self.SURFACE)
            grid.pack(fill="x")
            grid.columnconfigure(0, weight=3)
            grid.columnconfigure(1, weight=1)
            self._entry(grid, "СЕРВЕР", self.host_var).grid(
                row=0, column=0, sticky="ew", padx=(0, 14), pady=(0, 18)
            )
            self._entry(grid, "ПОРТ", self.port_var).grid(
                row=0, column=1, sticky="ew", pady=(0, 18)
            )
            self._entry(grid, "ИМЯ БАЗЫ", self.database_var).grid(
                row=1, column=0, sticky="ew", padx=(0, 14), pady=(0, 18)
            )
            self._entry(grid, "ПОЛЬЗОВАТЕЛЬ", self.user_var).grid(
                row=1, column=1, sticky="ew", pady=(0, 18)
            )
            self._entry(
                grid,
                "ПАРОЛЬ",
                self.password_var,
                show="●",
                reveal_toggle=True,
            ).grid(
                row=2, column=0, columnspan=2, sticky="ew"
            )
            ttk.Checkbutton(
                grid,
                text="Использовать SSL/TLS с проверкой сертификата сервера",
                variable=self.ssl_var,
            ).grid(row=3, column=0, columnspan=2, sticky="w", pady=(14, 0))
        else:
            self._label(parent, "Проверьте параметры", size=16, weight="bold").pack(
                anchor="w", pady=(2, 18)
            )
            rows = (
                ("Источник", self.source_var.get()),
                ("Назначение", "PostgreSQL"),
                ("Сервер", f"{self.host_var.get()}:{self.port_var.get()}"),
                ("База данных", self.database_var.get()),
                ("Пользователь", self.user_var.get()),
                ("SSL/TLS", "Включено" if self.ssl_var.get() else "Отключено"),
            )
            for index, (name, value) in enumerate(rows):
                row = tk.Frame(parent, bg=self.SURFACE)
                row.pack(fill="x", pady=8)
                self._label(row, name.upper(), size=9, color=self.MUTED, weight="bold").pack(
                    side="left", anchor="n", ipadx=5
                )
                self._label(
                    row,
                    value,
                    size=10,
                    anchor="e",
                    wraplength=650,
                    justify="right",
                ).pack(side="right", fill="x", expand=True)
                if index < len(rows) - 1:
                    tk.Frame(parent, bg=self.LINE, height=1).pack(fill="x", pady=(2, 0))

    def _browse_source(self) -> None:
        selected = filedialog.askopenfilename(
            parent=self.root,
            title="Выберите JSONL-файл",
            filetypes=(("JSON Lines", "*.jsonl"), ("Все файлы", "*.*")),
        )
        if selected:
            self.source_var.set(selected)

    def _next_step(self) -> None:
        if self.wizard_step == 0 and not self.source_var.get().strip():
            self._set_wizard_status("Укажите путь к JSONL-файлу.", error=True)
            return
        if self.wizard_step == 2:
            try:
                self._database_from_form()
            except ValueError as error:
                self._set_wizard_status(str(error), error=True)
                return
        self.load_error = None
        self.wizard_step += 1
        self._render_wizard_step()

    def _previous_step(self) -> None:
        self.wizard_step -= 1
        self._render_wizard_step()

    def _database_from_form(self) -> DatabaseConfig:
        try:
            database = DatabaseConfig(
                db_user=self.user_var.get().strip(),
                db_password=self.password_var.get(),
                db_host=self.host_var.get().strip(),
                db_port=int(self.port_var.get().strip()),
                db_name=self.database_var.get().strip(),
                db_ssl=self.ssl_var.get(),
            )
        except (ValueError, TypeError) as error:
            raise ValueError("Порт должен быть целым числом.") from error
        if not all((database.db_user, database.db_password, database.db_host, database.db_name)):
            raise ValueError("Заполните сервер, базу данных, пользователя и пароль.")
        if not 1 <= database.db_port <= 65535:
            raise ValueError("Порт должен быть в диапазоне от 1 до 65535.")
        return database

    def _set_wizard_status(self, text: str, *, error: bool = False) -> None:
        if self.wizard_status and self.wizard_status.winfo_exists():
            self.wizard_status.configure(text=text, fg=self.RED if error else self.GREEN)

    def _check_and_save(self) -> None:
        try:
            database = self._database_from_form()
            source_path = self.source_var.get().strip()
            if not source_path:
                raise ValueError("Укажите путь к JSONL-файлу.")
            updated_config = GatewayConfig(
                source_jsonl_path=source_path,
                database=database,
                statistics=self.config.statistics,
            )
        except ValueError as error:
            self._set_wizard_status(str(error), error=True)
            return

        self._set_wizard_status("Проверяем подключение…")

        def on_success(_: object) -> None:
            try:
                save_user_config(updated_config)
            except OSError as error:
                self._show_error(f"Не удалось сохранить настройки: {error}")
                return
            self.config = updated_config
            ConfigProvider.reset()
            self.load_error = None
            self.show_dashboard()

        self._run_async(lambda: test_connection(database), on_success)

    def show_dashboard(self) -> None:
        self._clear_window()
        self.root.configure(bg=self.BACKGROUND)

        shell = tk.Frame(self.root, bg=self.BACKGROUND)
        shell.pack(fill="both", expand=True)
        sidebar = tk.Frame(shell, bg=self.SIDEBAR, width=196)
        sidebar.pack(side="left", fill="y")
        sidebar.pack_propagate(False)
        self._label(
            sidebar,
            "LTN\nANALYTICS",
            size=16,
            color="#ffffff",
            weight="bold",
            bg=self.SIDEBAR,
            justify="left",
        ).pack(anchor="w", padx=25, pady=(30, 4))
        self._label(
            sidebar,
            "GATEWAY  /  01",
            size=8,
            color="#a8b6ad",
            weight="bold",
            bg=self.SIDEBAR,
        ).pack(anchor="w", padx=25, pady=(0, 34))
        tk.Frame(sidebar, bg="#33473c", height=1).pack(fill="x", padx=20)
        nav = tk.Label(
            sidebar,
            text="  Обзор",
            bg="#294137",
            fg=self.ACCENT,
            font=(self.FONT, 10, "bold"),
            anchor="w",
            padx=15,
            pady=13,
        )
        nav.pack(fill="x", padx=12, pady=(18, 5))
        self._label(
            sidebar,
            "ИСТОЧНИК",
            size=8,
            color="#9aaba1",
            weight="bold",
            bg=self.SIDEBAR,
        ).pack(anchor="w", padx=27, pady=(22, 8))
        self._label(
            sidebar,
            "JSONL  →  PostgreSQL",
            size=9,
            color="#ffffff",
            bg=self.SIDEBAR,
        ).pack(anchor="w", padx=27)
        self._label(
            sidebar,
            "Настройки хранятся локально",
            size=8,
            color="#9aaba1",
            bg=self.SIDEBAR,
            wraplength=168,
            justify="left",
        ).pack(side="bottom", anchor="w", padx=25, pady=24)

        main = tk.Frame(shell, bg=self.BACKGROUND)
        main.pack(side="left", fill="both", expand=True, padx=28, pady=22)
        top = tk.Frame(main, bg=self.BACKGROUND)
        top.pack(fill="x", pady=(0, 16))
        title = tk.Frame(top, bg=self.BACKGROUND)
        title.pack(side="left")
        self._label(title, "Рабочая панель", size=24, weight="bold", bg=self.BACKGROUND).pack(
            anchor="w"
        )
        self._label(
            title,
            "Импорт данных Factorio в базу",
            size=10,
            color=self.MUTED,
            bg=self.BACKGROUND,
        ).pack(anchor="w", pady=(5, 0))
        actions = tk.Frame(top, bg=self.BACKGROUND)
        actions.pack(side="right", anchor="n")
        settings_button = self._button(actions, "Настройки", self._open_settings)
        settings_button.pack(side="left", padx=(0, 8))
        test_button = self._button(actions, "Проверить подключение", self._test_saved_connection)
        test_button.pack(side="left", padx=(0, 8))
        run_button = self._button(actions, "Запустить импорт", self._start_import, primary=True)
        run_button.pack(side="left")
        self.busy_buttons.extend((test_button, run_button))

        self.dashboard_status = self._label(
            main,
            "",
            size=9,
            color=self.GREEN,
            bg=self.BACKGROUND,
        )
        self.dashboard_status.pack(fill="x", pady=(0, 12))

        stats_frame = tk.Frame(main, bg=self.BACKGROUND)
        stats_frame.pack(fill="x", pady=(0, 14))
        stats = self.config.statistics
        self._stat(stats_frame, "ЗАПУСКИ", str(stats.runs), "всего").pack(
            side="left", fill="both", expand=True, padx=(0, 10)
        )
        self._stat(stats_frame, "ЗАКАЗЫ", f"{stats.orders_sent:,}", "добавлено в БД").pack(
            side="left", fill="both", expand=True, padx=5
        )
        self._stat(stats_frame, "СОБЫТИЯ", f"{stats.events_sent:,}", "добавлено в БД").pack(
            side="left", fill="both", expand=True, padx=5
        )
        last_run = self._format_last_run(stats.last_run_at)
        self._stat(stats_frame, "ПОСЛЕДНИЙ ИМПОРТ", last_run, "локальная статистика").pack(
            side="left", fill="both", expand=True, padx=(5, 0)
        )

        connection_section = tk.Frame(
            main,
            bg=self.SURFACE,
            highlightthickness=1,
            highlightbackground=self.LINE,
        )
        connection_section.pack(fill="x", pady=(0, 14))
        connection_body = tk.Frame(connection_section, bg=self.SURFACE)
        connection_body.pack(fill="x", padx=22, pady=19)
        connection_header = tk.Frame(connection_body, bg=self.SURFACE)
        connection_header.pack(fill="x")
        self._label(connection_header, "НАЗНАЧЕНИЕ", size=8, color=self.MUTED, weight="bold").pack(
            side="left"
        )
        self._label(connection_header, "PostgreSQL", size=12, weight="bold").pack(side="right")
        self._label(
            connection_body,
            f"{self.config.database.db_host}:{self.config.database.db_port}  /  {self.config.database.db_name}",
            size=10,
            color=self.MUTED,
        ).pack(anchor="w", pady=(9, 0))
        self._label(
            connection_body,
            "SSL/TLS включён" if self.config.database.db_ssl else "SSL/TLS выключен",
            size=9,
            color=self.GREEN if self.config.database.db_ssl else self.MUTED,
        ).pack(anchor="w", pady=(5, 0))

        source_section = tk.Frame(
            main,
            bg=self.SURFACE,
            highlightthickness=1,
            highlightbackground=self.LINE,
        )
        source_section.pack(fill="x", pady=(0, 14))
        source_body = tk.Frame(source_section, bg=self.SURFACE)
        source_body.pack(fill="x", padx=22, pady=18)
        source_header = tk.Frame(source_body, bg=self.SURFACE)
        source_header.pack(fill="x")
        self._label(source_header, "ИСТОЧНИК ДАННЫХ", size=8, color=self.MUTED, weight="bold").pack(
            side="left"
        )
        source_path = Path(self.config.source_jsonl_path)
        source_state = "Файл найден" if source_path.is_file() else "Файл пока не найден"
        state_color = self.GREEN if source_path.is_file() else "#9b6a20"
        self._label(source_header, source_state, size=9, color=state_color, weight="bold").pack(
            side="right"
        )
        self._label(
            source_body,
            self.config.source_jsonl_path,
            size=10,
            color=self.INK,
            wraplength=710,
        ).pack(anchor="w", pady=(9, 0))

        self._label(
            main,
            f"Конфигурация: {CONFIG_PATH}",
            size=8,
            color=self.MUTED,
            bg=self.BACKGROUND,
            wraplength=760,
        ).pack(anchor="w", pady=(4, 0))

    def _stat(self, parent: tk.Frame, label: str, value: str, caption: str) -> tk.Frame:
        frame = tk.Frame(
            parent,
            bg=self.SURFACE,
            highlightthickness=1,
            highlightbackground=self.LINE,
        )
        body = tk.Frame(frame, bg=self.SURFACE)
        body.pack(fill="both", expand=True, padx=12, pady=10)
        self._label(body, label, size=8, color=self.MUTED, weight="bold").pack(anchor="w")
        self._label(body, value, size=16, weight="bold").pack(anchor="w", pady=(6, 1))
        self._label(body, caption, size=8, color=self.MUTED).pack(anchor="w")
        return frame

    @staticmethod
    def _format_last_run(value: str | None) -> str:
        if not value:
            return "—"
        try:
            return datetime.fromisoformat(value).astimezone().strftime("%d.%m.%Y %H:%M")
        except ValueError:
            return value

    def _open_settings(self) -> None:
        self.source_var = tk.StringVar(value=self.config.source_jsonl_path)
        self.host_var = tk.StringVar(value=self.config.database.db_host)
        self.port_var = tk.StringVar(value=str(self.config.database.db_port))
        self.database_var = tk.StringVar(value=self.config.database.db_name)
        self.user_var = tk.StringVar(value=self.config.database.db_user)
        self.password_var = tk.StringVar(value=self.config.database.db_password)
        self.ssl_var = tk.BooleanVar(value=self.config.database.db_ssl)
        self.settings_status: tk.Label | None = None
        self._render_settings_form()

    def _render_settings_form(self) -> None:
        self._clear_window()
        self.root.configure(bg=self.BACKGROUND)

        shell = tk.Frame(self.root, bg=self.BACKGROUND)
        shell.pack(fill="both", expand=True, padx=38, pady=24)
        header = tk.Frame(shell, bg=self.BACKGROUND)
        header.pack(fill="x", pady=(0, 18))
        titles = tk.Frame(header, bg=self.BACKGROUND)
        titles.pack(side="left")
        self._label(titles, "Настройки", size=22, weight="bold", bg=self.BACKGROUND).pack(
            anchor="w"
        )
        self._label(
            titles,
            "Источник данных и параметры PostgreSQL",
            size=10,
            color=self.MUTED,
            bg=self.BACKGROUND,
        ).pack(anchor="w", pady=(4, 0))
        cancel = self._button(header, "Отмена", self.show_dashboard)
        cancel.pack(side="right", anchor="n")

        form = tk.Frame(
            shell,
            bg=self.SURFACE,
            highlightthickness=1,
            highlightbackground=self.LINE,
        )
        form.pack(fill="both", expand=True)
        body = tk.Frame(form, bg=self.SURFACE)
        body.pack(fill="both", expand=True, padx=26, pady=20)

        self._label(body, "ИСТОЧНИК JSONL", size=9, color=self.MUTED, weight="bold").pack(
            anchor="w", pady=(0, 7)
        )
        source_row = tk.Frame(body, bg=self.SURFACE)
        source_row.pack(fill="x", pady=(0, 18))
        source_entry = tk.Entry(
            source_row,
            textvariable=self.source_var,
            relief="flat",
            bg="#f6f7f6",
            fg=self.INK,
            font=(self.FONT, 10),
            highlightthickness=1,
            highlightbackground=self.LINE,
        )
        source_entry.pack(side="left", fill="x", expand=True, ipady=9)
        self._bind_entry_clipboard(source_entry)
        self._button(source_row, "Обзор…", self._browse_source).pack(side="left", padx=(9, 0))

        self._label(body, "POSTGRESQL", size=9, color=self.MUTED, weight="bold").pack(
            anchor="w", pady=(0, 10)
        )
        grid = tk.Frame(body, bg=self.SURFACE)
        grid.pack(fill="x")
        grid.columnconfigure(0, weight=3)
        grid.columnconfigure(1, weight=1)
        self._entry(grid, "СЕРВЕР", self.host_var).grid(
            row=0, column=0, sticky="ew", padx=(0, 12), pady=(0, 12)
        )
        self._entry(grid, "ПОРТ", self.port_var).grid(
            row=0, column=1, sticky="ew", pady=(0, 12)
        )
        self._entry(grid, "ИМЯ БАЗЫ", self.database_var).grid(
            row=1, column=0, sticky="ew", padx=(0, 12), pady=(0, 12)
        )
        self._entry(grid, "ПОЛЬЗОВАТЕЛЬ", self.user_var).grid(
            row=1, column=1, sticky="ew", pady=(0, 12)
        )
        self._entry(
            grid,
            "ПАРОЛЬ",
            self.password_var,
            show="●",
            reveal_toggle=True,
        ).grid(
            row=2, column=0, columnspan=2, sticky="ew"
        )
        ttk.Checkbutton(
            body,
            text="Использовать SSL/TLS с проверкой сертификата сервера",
            variable=self.ssl_var,
        ).pack(anchor="w", pady=(14, 0))

        footer = tk.Frame(shell, bg=self.BACKGROUND)
        footer.pack(fill="x", pady=(14, 0))
        self.settings_status = self._label(
            footer,
            "",
            size=9,
            color=self.MUTED,
            bg=self.BACKGROUND,
            wraplength=520,
        )
        self.settings_status.pack(side="left", fill="x", expand=True)
        save_button = self._button(
            footer,
            "Сохранить настройки",
            self._save_settings_form,
            primary=True,
        )
        save_button.pack(side="right")
        check_button = self._button(
            footer,
            "Проверить подключение",
            self._test_settings_connection,
        )
        check_button.pack(side="right", padx=(0, 8))
        self.busy_buttons.extend((save_button, check_button))

    def _settings_database(self) -> DatabaseConfig:
        try:
            database = DatabaseConfig(
                db_user=self.user_var.get().strip(),
                db_password=self.password_var.get(),
                db_host=self.host_var.get().strip(),
                db_port=int(self.port_var.get().strip()),
                db_name=self.database_var.get().strip(),
                db_ssl=self.ssl_var.get(),
            )
        except (ValueError, TypeError) as error:
            raise ValueError("Проверьте номер порта.") from error
        if not all((database.db_user, database.db_password, database.db_host, database.db_name)):
            raise ValueError("Заполните все параметры PostgreSQL.")
        if not 1 <= database.db_port <= 65535:
            raise ValueError("Порт должен быть в диапазоне от 1 до 65535.")
        return database

    def _test_settings_connection(self) -> None:
        try:
            database = self._settings_database()
        except ValueError as error:
            self.settings_status.configure(text=str(error), fg=self.RED)
            return
        self.settings_status.configure(text="Проверяем подключение…", fg=self.MUTED)

        def on_success(_: object) -> None:
            if self.settings_status and self.settings_status.winfo_exists():
                self.settings_status.configure(text="Подключение успешно проверено.", fg=self.GREEN)

        self._run_async(lambda: test_connection(database), on_success)

    def _save_settings_form(self) -> None:
        try:
            database = self._settings_database()
            source_path = self.source_var.get().strip()
            if not source_path:
                raise ValueError("Укажите путь к JSONL-файлу.")
            updated_config = self.config.model_copy(
                update={"source_jsonl_path": source_path, "database": database}
            )
            save_user_config(updated_config)
        except (OSError, ValueError) as error:
            self.settings_status.configure(text=str(error), fg=self.RED)
            return

        self.config = updated_config
        ConfigProvider.reset()
        self.show_dashboard()
        if self.dashboard_status:
            self.dashboard_status.configure(text="Настройки сохранены.", fg=self.GREEN)

    def _test_saved_connection(self) -> None:
        if self.dashboard_status:
            self.dashboard_status.configure(text="Проверяем подключение…", fg=self.MUTED)

        def on_success(_: object) -> None:
            if self.dashboard_status:
                self.dashboard_status.configure(text="Подключение успешно проверено.", fg=self.GREEN)

        self._run_async(lambda: test_connection(self.config.database), on_success)

    def _start_import(self) -> None:
        source = Path(self.config.source_jsonl_path)
        if not source.is_file():
            self._show_error(f"Файл данных не найден: {source}")
            return
        if self.dashboard_status:
            self.dashboard_status.configure(text="Читаем файл и отправляем новые записи…", fg=self.MUTED)

        def on_success(result: object) -> None:
            if not isinstance(result, ImportResult):
                self._show_error("Импорт вернул неизвестный результат.")
                return
            old = self.config.statistics
            statistics = RunStatistics(
                runs=old.runs + 1,
                snapshots_processed=old.snapshots_processed + result.snapshots_processed,
                orders_sent=old.orders_sent + result.orders_sent,
                events_sent=old.events_sent + result.events_sent,
                last_run_at=datetime.now().astimezone().isoformat(timespec="minutes"),
            )
            self.config = self.config.model_copy(update={"statistics": statistics})
            try:
                save_user_config(self.config)
            except OSError as error:
                self._show_error(f"Импорт завершён, но статистику сохранить не удалось: {error}")
                self.show_dashboard()
                return
            self.show_dashboard()
            if self.dashboard_status:
                self.dashboard_status.configure(
                    text=(
                        f"Готово: обработано снимков {result.snapshots_processed}, "
                        f"добавлено заказов {result.orders_sent}, событий {result.events_sent}."
                    ),
                    fg=self.GREEN,
                )

        self._run_async(import_jsonl_data, on_success)


def main() -> None:
    GatewayApp().run()