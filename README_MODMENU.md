# StandRise RE — Mod Menu (iOS, Theos)

Мод-меню для `com.standrise.game` (StandRise RE 1.0F5H8, Unity 2021.3.45f1, IL2CPP v31).
Оффсеты и RVA вытащены из `dump/il2cpp/dump.cs` (Il2CppDumper 6.7.46) и зафиксированы в `Cheat/Offsets.h`.

## Что внутри

| Файл | Назначение |
|---|---|
| `Bootstrap.mm` | Точка входа dylib, отложенная инициализация и ретраи, пока игра грузится |
| `Cheat/Runtime.mm` | База `UnityFramework`, `dlsym` для `il2cpp_*`, поиск классов/синглтонов |
| `Cheat/Game.mm` | Список игроков, команда, ник, оружие, скелет (BipedMap), камера, WorldToScreen |
| `Cheat/Features.mm` | Аимбот, сбор данных ESP, граната, wallshot/rapid fire/jump, конфиг |
| `Cheat/Offsets.h` | Все оффсеты полей и RVA методов (единственное место для правок) |
| `UI/ESPDrawView.mm` | Прозрачный overlay-виндоу, CADisplayLink, отрисовка ESP/FOV/гранаты |
| `UI/MenuWindow.mm` | Меню: вкладки Legit / Visuals / Misc / Config, свитчи, слайдеры, цвета |
| `Touch/TouchHook.mm` | Свайзл `-[UIApplication sendEvent:]`, детект тапа тремя пальцами |
| `tools/verify_offsets.ps1` | Пере-вывод оффсетов/RVA из `dump.cs` (для новой версии игры) |

## Функционал

**Открытие меню** — тап тремя пальцами в любом месте (открыть/закрыть).

**Legit**
- Aimbot (вкл/выкл)
- Target bone: Head / Neck / Chest
- FOV radius (ползунок, это же радиус круга на экране)
- Smoothing
- Auto shot
- Visible aim (camera) — доворот камеры к цели (видимый аим)
- Draw FOV circle
- Цвет круга/маркера (красный, зелёный, голубой, оранжевый, жёлтый, фиолетовый, белый)

**Visuals**
- Name ESP
- Weapon ESP
- 2D Box (с уголками)
- Chams (полупрозрачная заливка + точки скелета)
- Skeleton
- Grenade trajectory (предсказание дуги от камеры)
- Team check, Show distance
- Цвет ESP и цвет Chams

**Misc**
- Wallshot — `_armorPenetration = 1.0`, `_penetrationPower = 200` у текущего `GunParameters`
- Rapid fire — перезапись `_fireRate` (ползунок 300–2000 rpm), с восстановлением при выключении
- Infinite jump / Bunny hop — вызов `MovementController.Jump` + выставление состояния `Jump` на кадрах, когда персонаж на земле

**Config** — сохранение/загрузка/сброс (`NSUserDefaults`), диагностика (адрес UnityFramework, il2cpp, PlayerManager, LocalPlayer, камера, число игроков, статус аима).

## Сборка (macOS + Theos)

```bash
# Theos: https://theos.dev
cd dump/modmenu
make clean && make
# результат: .theos/obj/StandRiseMenu.dylib (или .theos/obj/debug/...)
```

Требуется toolchain с iOS SDK (Theos ставит сам). Архитектура `arm64`, минимальная iOS 13.0 (`TARGET` в `Makefile`).

## Сборка без Mac (GitHub Actions)

Workflow уже лежит в `.github/workflows/build.yml` — Mac и Theos на твоей машине не нужны, всё собирается на `macos-15` раннере GitHub.

1. Создай репозиторий (можно приватный) и залей **содержимое папки `dump/modmenu`** в корень репозитория.
   Если заливаешь всю папку `dump` — workflow сам найдёт `modmenu/Makefile` (и вариант `dump/modmenu/Makefile` тоже).
2. Открой **Actions → Build StandRiseMenu → Run workflow**.
   Любой `push` в `main`/`master`/`dev` тоже запускает сборку.
3. Через ~5–10 минут (первый раз дольше — качается SDK) скачай артефакт **`StandRiseMenu-dylib`**.
4. Дальше — Sideloadly / ESign, как в разделе «Внедрение».
5. Для релиза: поставь тег и запушь —
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   dylib автоматически прикрепится к GitHub Release.

Что делает workflow:

- ставит Theos (`theos/theos`, shallow clone);
- через sparse checkout клонирует **только один** iPhoneOS SDK (16.5, иначе самый свежий) — не тянет весь репозиторий SDK на несколько гигабайт;
- кэширует `~/theos/sdks` между запусками (`actions/cache`);
- ставит `ldid` через Homebrew (нужен Theos для подписи);
- собирает `StandRiseMenu.dylib` (`make`), проверяет `lipo`/`otool`;
- выкладывает артефакт на 30 дней и ассет релиза по тегу.

> Если сборка упала — открой лог шага **Build dylib**. Чаще всего это ошибка компиляции в `.mm`; правки только в исходниках, workflow трогать не нужно.

## Внедрение

### Вариант A — Sideloadly (Windows/macOS, без джейлбрейка)
1. Собрать `StandRiseMenu.dylib` (см. выше; собрать можно на macOS / CI / GitHub Actions с Theos).
2. Sideloadly → выбрать IPA → **Advanced Options → Inject dylibs/frameworks** → добавить `StandRiseMenu.dylib`.
3. Указать Apple ID, установить. Sideloadly сам вставит `LC_LOAD_DYLIB` и переподпишет.

### Вариант B — ESign / TrollStore (на устройстве)
1. Закинуть IPA и dylib на устройство.
2. ESign → подпись → **Inject** → выбрать dylib → установить.

### Вариант C — скрипт (macOS, jailbreak/ldid)
```bash
chmod +x scripts/inject_ipa.sh
./scripts/inject_ipa.sh "StandRise-RE-1.0F5H8.ipa" ".theos/obj/StandRiseMenu.dylib" "StandRiseMenu.ipa"
```
Скрипт распаковывает IPA, кладёт dylib в `Payload/StandRiseRE.app/Frameworks/`,
вставляет load command через `insert_dylib`, подписывает `ldid` и собирает IPA обратно.

> Для non-jailbreak установки финальную подпись всё равно делать Sideloadly/ESign.

## Оффсеты (из dump.cs, TypeDefIndex в скобках)

| Класс | Поле | Offset |
|---|---|---|
| PlayerManager (2794) | `Dictionary<int,PlayerController>` | 0x20 |
| | `HashSet<PlayerController>` | 0x28 |
| | LocalPlayer | 0x68 |
| | Spectated | 0x70 |
| PlayerController (2782) | BipedMap | 0x30 |
| | Team (byte) | 0x59 |
| | AimController | 0x60 |
| | WeaponryController | 0x68 |
| | MovementController | 0x78 |
| | PhotonPlayer | 0x130 |
| BipedMap (2774) | Head / Neck / Spine1 / Spine2 | 0x18 / 0x20 / 0x28 / 0x30 |
| | Shoulders / Arms / Hands | 0x38–0x70 |
| | Hip / Legs / Feet | 0x78–0xA8 |
| WeaponryController (2815) | current WeaponController | 0x98 |
| WeaponController (4100) | WeaponParameters | 0x68 |
| GunParameters (4142) | `_damage` | 0x98 |
| | `_hitRange` | 0xA0 |
| | `_fireRate` (int) | 0xA4 |
| | `_recoilControl` | 0xA8 |
| | `_armorPenetration` | 0xF8 |
| | `_penetrationPower` | 0xFC |

RVA методов (UnityFramework, arm64):

| Метод | RVA |
|---|---|
| `Camera.get_main()` | 0x31F41B0 |
| `Camera.WorldToScreenPoint(Vector3)` | 0x31F3EDC |
| `Camera.get_pixelWidth/Height` | 0x31F3554 / 0x31F3594 |
| `Transform.get_position()` | 0x3223A34 |
| `Transform.get_forward()` | 0x322401C |
| `Component.get_transform()` | 0x3219CD8 |
| `Object.FindObjectOfType(Type)` | 0x321EF6C |
| `PhotonPlayer.get_NickName()` | 0x13B54E4 |
| `WeaponController.get_BFHHCEDEBACAHEC()` (имя оружия) | 0x16FACEC |
| `AimController.BHAHDCEAFECAEAB(Vector3)` | 0x155F428 |
| `MovementController.get_GBHEBECHDAHGDEB()` (на земле) | 0x15508C8 |
| `MovementController.set_GEDFEECEEABHHFF(state)` | 0x1550A60 |
| `MovementController.BGCCGGDGACEBDEG(float)` (jump) | 0x15519E4 |
| `WeaponryController.GECHEGCCCFCBFFD()` (fire down) | 0x1533B9C |
| `WeaponryController.GBBEDFCGGBGBADG()` (fire up) | 0x1533C48 |

## Что проверить на устройстве (один прогон)

Код собирается и работает по структуре, но три якоря в этом билде определены по сигнатурам, а не по декомпиляции. Проверяй по вкладке **Config → Diagnostics** и по поведению:

1. **AimController.BHAHDCEAFECAEAB(Vector3)** — если аим не двигает прицел, это `SetSpineTarget`, а не `SetLookPoint`. Тогда заменить RVA на реальный сеттер углов обзора (искать в `AimController` методы с `float,float` или поле `aimingData`).
2. **MovementController.BGCCGGDGACEBDEG(float)** — если прыжок не срабатывает, оставить только `set_GEDFEECEEABHHFF(1)` либо подставить реальный `Jump`.
3. **WeaponryController.GECHEGCCCFCBFFD / GBBEDFCGGBGBADG** — это fire down/up; при некорректном поведении auto shot отключить (по умолчанию выключен).

Всё остальное (ESP, скелет, ник, оружие, WorldToScreen, wallshot/rapid fire) опирается на подтверждённые поля и методы.

## Chams — важное уточнение

В этой реализации «chams» — это **overlay-chams**: полупрозрачная заливка 2D-бокса + точки скелета поверх игры. Это не подмена материалов через `Renderer.material`, потому что для настоящих 3D-chams нужен хук рендера Unity (Metal) и доступ к `SkinnedMeshRenderer` каждого игрока. Если нужен именно material-chams — это следующий этап (хук `Camera.onPreCull` + покраска материалов через Unity API).

## Диагностика

- Вкладка Config показывает адреса и статусы в реальном времени.
- Логи ищи в Console.app (macOS) по процессу `StandRiseRE`.
- Если `PlayerManager: 0x0` — `il2cpp_*` не экспортированы или игра ещё грузится; меню ретраит инициализацию каждые 2 секунды.

## Пере-пиннинг под новую версию игры

```powershell
powershell -ExecutionPolicy Bypass -File tools\verify_offsets.ps1 "C:\path\to\new\dump.cs"
```
Скрипт выведет актуальные оффсеты полей и RVA — обновить `Cheat/Offsets.h`, пересобрать.

---

Made By @NullRoutee
