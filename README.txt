# Tactical Strike 1.6 — Руководство пользователя и разработчика

## 1. Что представляет собой игра
**Tactical Strike 1.6** — это автономный тактический 3D-шутер от первого лица для Windows на базе **Godot Engine 4.x**, вдохновлённый классическим соревновательным геймплеем Counter-Strike 1.6. Игра полностью работает офлайн, не использует браузер или HTML и включает ботов с ИИ, раундовую экономику, 25 видов оружия и 4 карты.

## 2. Какие файлы входят в проект
* `project.godot` — главный конфигурационный файл движка Godot 4.
* `export_presets.cfg` — профили компиляции в Windows `.exe` (обычный и портативный).
* `scenes/main.tscn` — стартовая 3D-сцена.
* `data/weapons/weapon_database.gd` — база характеристик всех 25 видов оружия и C4.
* `data/maps/map_builder.gd` — генератор 3D-геометрии, освещения и навигации карт.
* `data/settings/settings_manager.gd` — сохранение и применение настроек графики, звука и клавиш.
* `scripts/player/combat_actor.gd` — контроллер физики игрока, стрельбы, отдачи и C4.
* `scripts/bots/bot_ai.gd` — искусственный интеллект ботов (3 уровня сложности).
* `scripts/economy/economy_manager.gd` — экономика раундов и магазин.
* `scripts/audio/sfx_manager.gd` — процедурный синтезатор звуков WAV.
* `scripts/ui/ui_controller.gd` — главное меню, HUD, магазин, радар и таблица счёта.
* `tests/test_suite.gd` — автоматизированные тесты систем.

## 3. Системные требования
* **ОС:** Windows 10 / Windows 11 (64-bit).
* **Процессор:** 2-ядерный x86_64 2.0 ГГц и выше.
* **Оперативная память:** 2 ГБ ОЗУ.
* **Видеокарта:** любая с поддержкой Vulkan 1.0 или OpenGL 3.3 (DirectX 11/12).
* **Место на диске:** ~150 МБ.

## 4. Как запустить готовый .exe
После выполнения скрипта сборки (`generate_and_build.ps1`) откройте папку `build/Windows/` и запустите `CounterStrikeInspired.exe` (рядом должен находиться `CounterStrikeInspired.pck`), либо запустите однофайловую сборку `build/Portable/CounterStrikeInspired_Portable.exe`.

## 5. Как распаковать переносимую сборку
Переносимая сборка `CounterStrikeInspired_Portable.exe` содержит упакованный внутрь `.pck`-архив (`embed_pck=true`). Достаточно скопировать этот единственный `.exe`-файл в любую папку на любом ПК с Windows и запустить двойным щелчком — установка движка не требуется.

## 6. Как открыть исходный проект в игровом движке
1. Запустите **Godot Engine 4.2+** (Standard version).
2. В менеджере проектов нажмите **Import (Импорт)**.
3. Укажите путь к файлу `CounterStrikeInspired/project.godot`.
4. Нажмите **Import & Edit** и нажмите `F5` для запуска игры из редактора.

## 7. Как установить необходимые инструменты разработки
1. Скачайте бесплатный движок **Godot Engine 4.2 или 4.3** с официального сайта `https://godotengine.org/download/windows/`.
2. Для компиляции в `.exe` внутри редактора выберите меню **Editor -> Manage Export Templates -> Download and Install**.

## 8. Как собрать игру самостоятельно
Выполните в терминале PowerShell из корня проекта:
```powershell
godot --headless --export-release "Windows Desktop" "build/Windows/CounterStrikeInspired.exe"
godot --headless --export-release "Windows Portable" "build/Portable/CounterStrikeInspired_Portable.exe"