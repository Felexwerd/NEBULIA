using Microsoft.Maui.ApplicationModel;
using Microsoft.Maui.Devices;
using Microsoft.Maui.Storage;
using System.Globalization;

#if ANDROID
using Android.App;
using Android.Content;
using Android.Content.PM;
using Android.OS;
#endif

namespace NebulaBoost;

public partial class MainPage : ContentPage
{
    private bool _isRussian;

    public MainPage()
    {
        InitializeComponent();
        _isRussian = Preferences.Get("app_language", "ru") == "ru";
        RefreshDeviceInfo();
        ApplyLanguage();
    }

    private void RefreshDeviceInfo()
    {
        DeviceNameLabel.Text = DeviceInfo.Current.Model;
        OsValueLabel.Text = $"{DeviceInfo.Current.Platform} {DeviceInfo.Current.VersionString}";
        var processMb = GC.GetTotalMemory(false) / (1024d * 1024d);
        RamValueLabel.Text = $"{processMb:0} MB";
    }

    private async void OnBoostClicked(object sender, EventArgs e)
    {
        BoostButton.IsEnabled = false;
        BoostButton.Text = _isRussian ? "ИДЁТ ПРОВЕРКА…" : "CHECKING…";
        StatusLabel.Text = _isRussian ? "АНАЛИЗ…" : "ANALYZING…";
        DeviceNoteLabel.Text = _isRussian
            ? "Проверяем доступные показатели устройства…"
            : "Checking available device metrics…";

        try
        {
            await Task.Delay(250);
            // This safely releases unused managed memory belonging to NEBULA BOOST only.
            var beforeMb = GC.GetTotalMemory(false) / (1024d * 1024d);
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            var afterMb = GC.GetTotalMemory(true) / (1024d * 1024d);

            RefreshDeviceInfo();

            var summary = GetBoostSummary(beforeMb, afterMb);
            DeviceNoteLabel.Text = summary;
            StatusLabel.Text = _isRussian ? "ПРОВЕРЕНО" : "CHECKED";
        }
        catch (Exception ex)
        {
            StatusLabel.Text = _isRussian ? "ОШИБКА" : "ERROR";
            DeviceNoteLabel.Text = _isRussian
                ? "Не удалось проверить показатели. Откройте диагностику для подробностей."
                : "Could not check metrics. Open Diagnostics for details.";
            await DisplayAlert(_isRussian ? "Ошибка Smart Boost" : "Smart Boost error",
                ex.Message, _isRussian ? "Закрыть" : "Close");
        }
        finally
        {
            BoostButton.Text = _isRussian ? "ЗАПУСТИТЬ SMART BOOST" : "RUN SMART BOOST";
            BoostButton.IsEnabled = true;
        }
    }

    private string GetBoostSummary(double beforeMb, double afterMb)
    {
        var lines = new List<string>();
        lines.Add(_isRussian
            ? $"Проверка завершена. Память приложения: {afterMb:0} МБ."
            : $"Check complete. App memory: {afterMb:0} MB.");

        if (beforeMb > afterMb + 1)
            lines.Add(_isRussian
                ? $"Освобождено около {beforeMb - afterMb:0} МБ памяти самого NEBULA BOOST."
                : $"Released about {beforeMb - afterMb:0} MB used by NEBULA BOOST itself.");
        else
            lines.Add(_isRussian
                ? "Очистка памяти самого NEBULA BOOST выполнена; заметного изменения не потребовалось."
                : "NEBULA BOOST's own memory cleanup ran; no significant change was needed.");

#if ANDROID
        try
        {
            var context = Android.App.Application.Context;
            var manager = context.GetSystemService(Context.ActivityService) as ActivityManager;
            var memory = new ActivityManager.MemoryInfo();
            manager?.GetMemoryInfo(memory);
            if (manager is not null)
            {
                var availableGb = memory.AvailMem / 1024d / 1024d / 1024d;
                var totalGb = memory.TotalMem / 1024d / 1024d / 1024d;
                lines.Add(_isRussian
                    ? $"Свободная системная ОЗУ: {availableGb:0.0} из {totalGb:0.0} ГБ."
                    : $"Available system RAM: {availableGb:0.0} of {totalGb:0.0} GB.");
                if (memory.LowMemory)
                    lines.Add(_isRussian
                        ? "Android сообщает о нехватке памяти. Закройте ненужные приложения."
                        : "Android reports low memory. Close apps you don't need.");
            }

            var stat = new Android.OS.StatFs(Android.OS.Environment.DataDirectory!.AbsolutePath);
            var freeGb = stat.AvailableBytes / 1024d / 1024d / 1024d;
            var totalStorageGb = stat.TotalBytes / 1024d / 1024d / 1024d;
            lines.Add(_isRussian
                ? $"Свободное хранилище: {freeGb:0.0} из {totalStorageGb:0.0} ГБ."
                : $"Free storage: {freeGb:0.0} of {totalStorageGb:0.0} GB.");
        }
        catch
        {
            // Keep the successful app-memory check even if an optional Android metric is unavailable.
        }
#endif
        lines.Add(_isRussian
            ? "Важно: Android не разрешает этому приложению принудительно закрывать другие приложения или разгонять CPU/GPU."
            : "Note: Android does not allow this app to force-stop other apps or overclock the CPU/GPU.");
        return string.Join("\n", lines);
    }

    private async void OnDiagnosticsClicked(object sender, EventArgs e)
    {
        try
        {
            StatusLabel.Text = _isRussian ? "ДИАГНОСТИКА" : "DIAGNOSTICS";
            var report = GetSystemReport();
            var title = _isRussian ? "Диагностика устройства" : "Device diagnostics";
            var message = _isRussian
                ? $"{report}\n\nПамять приложения — это не вся оперативная память телефона. Температура CPU/GPU и FPS зависят от модели и обычно недоступны универсальному приложению."
                : $"{report}\n\nApp memory is not the phone's total RAM. CPU/GPU temperature and FPS depend on the device and usually aren't exposed to a general-purpose app.";
            await DisplayAlert(title, message, _isRussian ? "Готово" : "Done");
        }
        catch (Exception ex)
        {
            await DisplayAlert(_isRussian ? "Ошибка диагностики" : "Diagnostics failed",
                ex.Message, _isRussian ? "Закрыть" : "Close");
        }
        finally
        {
            StatusLabel.Text = _isRussian ? "ГОТОВО" : "READY";
        }
    }

    private async void OnGamesClicked(object sender, EventArgs e)
    {
#if ANDROID
        try
        {
            var context = Android.App.Application.Context;
            var pm = context.PackageManager;
            var intent = new Android.Content.Intent(Android.Content.Intent.ActionMain);
            intent.AddCategory(Android.Content.Intent.CategoryLauncher);
            var activities = pm.QueryIntentActivities(intent, PackageInfoFlags.MatchAll);
            var apps = activities
                .Where(x => x.ActivityInfo?.PackageName is not null
                    && x.ActivityInfo.PackageName != context.PackageName)
                .Select(x => new
                {
                    Name = x.LoadLabel(pm)?.ToString() ?? x.ActivityInfo!.PackageName!,
                    Package = x.ActivityInfo!.PackageName!
                })
                .GroupBy(x => x.Package)
                .Select(g => g.First())
                .OrderBy(x => x.Name, StringComparer.CurrentCultureIgnoreCase)
                .ToList();

            if (apps.Count == 0)
            {
                await DisplayAlert(_isRussian ? "Библиотека игр" : "Game library",
                    _isRussian
                        ? "Android не показал доступные приложения. Проверьте видимость приложений для этой сборки."
                        : "Android returned no visible launchable apps. Check package visibility for this build.",
                    _isRussian ? "Закрыть" : "Close");
                return;
            }

            var options = apps.Select(x => x.Name).ToArray();
            var chosen = await DisplayActionSheet(
                _isRussian ? $"Приложения на устройстве ({apps.Count})" : $"Launchable apps ({apps.Count})",
                _isRussian ? "Отмена" : "Cancel", null, options);

            var selected = apps.FirstOrDefault(x => x.Name == chosen);
            if (selected is null) return;

            Preferences.Set("selected_game_name", selected.Name);
            Preferences.Set("selected_game_package", selected.Package);
            SelectedGameActions.IsVisible = true;
            GamesDescLabel.Text = (_isRussian ? "Выбрано: " : "Selected: ") + selected.Name;
            var launchIntent = pm.GetLaunchIntentForPackage(selected.Package);
            if (launchIntent is not null)
            {
                launchIntent.AddFlags(ActivityFlags.NewTask);
                context.StartActivity(launchIntent);
            }
            else
            {
                await DisplayAlert(_isRussian ? "Не удалось запустить" : "Cannot launch",
                    _isRussian ? "У приложения нет доступного экрана запуска." : "This app has no launchable activity.",
                    _isRussian ? "Закрыть" : "Close");
            }
        }
        catch (Exception ex)
        {
            await DisplayAlert(_isRussian ? "Ошибка библиотеки" : "Game library error",
                ex.Message, _isRussian ? "Закрыть" : "Close");
        }
#else
        await DisplayAlert("NEBULA BOOST", "Android-only feature.", "OK");
#endif
    }

    private async void OnLaunchSelectedGameClicked(object sender, EventArgs e)
    {
#if ANDROID
        var packageName = Preferences.Get("selected_game_package", "");
        var gameName = Preferences.Get("selected_game_name", "");
        if (string.IsNullOrWhiteSpace(packageName))
        {
            await DisplayAlert(_isRussian ? "Игра не выбрана" : "No game selected",
                _isRussian ? "Сначала откройте «Игры» и выберите приложение." : "Open Games and select an app first.",
                _isRussian ? "Понятно" : "OK");
            return;
        }

        try
        {
            var context = Android.App.Application.Context;
            var intent = context.PackageManager?.GetLaunchIntentForPackage(packageName);
            if (intent is null)
            {
                await DisplayAlert(_isRussian ? "Не удалось запустить" : "Cannot launch",
                    _isRussian ? "Android не предоставляет экран запуска для этого приложения." : "Android did not provide a launch activity for this app.",
                    _isRussian ? "Закрыть" : "Close");
                return;
            }
            intent.AddFlags(ActivityFlags.NewTask);
            context.StartActivity(intent);
        }
        catch (Exception ex)
        {
            await DisplayAlert(_isRussian ? "Ошибка запуска" : "Launch error", ex.Message,
                _isRussian ? "Закрыть" : "Close");
        }
#else
        await DisplayAlert("NEBULA BOOST", "Android-only feature.", "OK");
#endif
    }

    private async void OnSelectedGameSettingsClicked(object sender, EventArgs e)
    {
        var packageName = Preferences.Get("selected_game_package", "");
        var gameName = Preferences.Get("selected_game_name", "");
        if (string.IsNullOrWhiteSpace(packageName))
        {
            await DisplayAlert(_isRussian ? "Игра не выбрана" : "No game selected",
                _isRussian ? "Сначала выберите приложение в библиотеке игр." : "Select an app in the game library first.",
                _isRussian ? "Понятно" : "OK");
            return;
        }

        var graphics = Preferences.Get(ProfileKey(packageName, "graphics"), "Balanced");
        var fps = Preferences.Get(ProfileKey(packageName, "fps"), "60");
        var touch = Preferences.Get(ProfileKey(packageName, "touch"), "Normal");
        var power = Preferences.Get(ProfileKey(packageName, "power"), "Balanced");

        var graphicsChoice = await DisplayActionSheet(
            _isRussian ? $"Профиль: {gameName} — графика" : $"Profile: {gameName} — graphics",
            _isRussian ? "Отмена" : "Cancel", null,
            _isRussian ? new[] { "Производительность", "Баланс", "Качество" } : new[] { "Performance", "Balanced", "Quality" });
        if (string.IsNullOrWhiteSpace(graphicsChoice) || graphicsChoice == (_isRussian ? "Отмена" : "Cancel")) return;
        graphics = graphicsChoice == (_isRussian ? "Производительность" : "Performance") ? "Performance"
            : graphicsChoice == (_isRussian ? "Качество" : "Quality") ? "Quality" : "Balanced";

        var fpsChoice = await DisplayActionSheet(
            _isRussian ? "Целевой FPS (рекомендация)" : "Target FPS (recommendation)",
            _isRussian ? "Оставить" : "Keep current", null, "30", "60", "90", "120");
        if (!string.IsNullOrWhiteSpace(fpsChoice) && fpsChoice != (_isRussian ? "Оставить" : "Keep current"))
            fps = fpsChoice;

        var touchChoice = await DisplayActionSheet(
            _isRussian ? "Чувствительность управления" : "Control sensitivity",
            _isRussian ? "Оставить" : "Keep current", null,
            _isRussian ? new[] { "Низкая", "Обычная", "Высокая" } : new[] { "Low", "Normal", "High" });
        if (!string.IsNullOrWhiteSpace(touchChoice) && touchChoice != (_isRussian ? "Оставить" : "Keep current"))
            touch = touchChoice == (_isRussian ? "Низкая" : "Low") ? "Low"
                : touchChoice == (_isRussian ? "Высокая" : "High") ? "High" : "Normal";

        var powerChoice = await DisplayActionSheet(
            _isRussian ? "Приоритет профиля" : "Profile priority",
            _isRussian ? "Оставить" : "Keep current", null,
            _isRussian ? new[] { "Производительность", "Баланс батареи" } : new[] { "Performance", "Battery balance" });
        if (!string.IsNullOrWhiteSpace(powerChoice) && powerChoice != (_isRussian ? "Оставить" : "Keep current"))
            power = powerChoice == (_isRussian ? "Производительность" : "Performance") ? "Performance" : "Balanced";

        Preferences.Set(ProfileKey(packageName, "graphics"), graphics);
        Preferences.Set(ProfileKey(packageName, "fps"), fps);
        Preferences.Set(ProfileKey(packageName, "touch"), touch);
        Preferences.Set(ProfileKey(packageName, "power"), power);
        UpdateGameProfileSummary();

        await DisplayAlert(_isRussian ? "Профиль сохранён" : "Profile saved",
            _isRussian
                ? $"Настройки профиля для {gameName} сохранены на этом устройстве. Это рекомендации NEBULA BOOST: они не меняют графику или FPS внутри самой игры автоматически."
                : $"The profile for {gameName} is saved on this device. These are NEBULA BOOST recommendations; they do not automatically change the game's graphics or FPS.",
            _isRussian ? "Готово" : "Done");
    }

    private static string ProfileKey(string packageName, string setting) =>
        $"game_profile_{packageName}_{setting}";

    private void UpdateGameProfileSummary()
    {
        var packageName = Preferences.Get("selected_game_package", "");
        if (string.IsNullOrWhiteSpace(packageName))
        {
            GameProfileCard.IsVisible = false;
            return;
        }

        var graphics = Preferences.Get(ProfileKey(packageName, "graphics"), "Balanced");
        var fps = Preferences.Get(ProfileKey(packageName, "fps"), "60");
        var touch = Preferences.Get(ProfileKey(packageName, "touch"), "Normal");
        var power = Preferences.Get(ProfileKey(packageName, "power"), "Balanced");

        string Local(string value) => !_isRussian ? value : value switch
        {
            "Performance" => "Производительность",
            "Balanced" => "Баланс",
            "Quality" => "Качество",
            "Low" => "Низкая",
            "Normal" => "Обычная",
            "High" => "Высокая",
            _ => value
        };

        GameProfileHeadingLabel.Text = _isRussian ? "СОХРАНЁННЫЙ ПРОФИЛЬ ИГРЫ" : "SAVED GAME PROFILE";
        GameProfileSummaryLabel.Text = _isRussian
            ? $"Графика: {Local(graphics)} • Цель FPS: {fps} • Управление: {Local(touch)} • Приоритет: {Local(power)}\nПараметры сохранены как рекомендации."
            : $"Graphics: {graphics} • FPS target: {fps} • Controls: {touch} • Priority: {power}\nSaved as recommendations.";
        GameProfileCard.IsVisible = true;
    }

    private string GetSystemReport()
    {
        var model = DeviceInfo.Current.Model;
        var os = $"{DeviceInfo.Current.Platform} {DeviceInfo.Current.VersionString}";
        var appMemory = GC.GetTotalMemory(false) / (1024d * 1024d);
        var selectedGame = Preferences.Get("selected_game_name", "");

        var lines = new List<string>
        {
            $"{(_isRussian ? "Устройство" : "Device")}: {model}",
            $"{(_isRussian ? "Система" : "System")}: {os}",
            $"{(_isRussian ? "Память NEBULA BOOST" : "NEBULA BOOST process memory")}: {appMemory:0} MB"
        };

#if ANDROID
        try
        {
            var stat = new Android.OS.StatFs(Android.OS.Environment.DataDirectory!.AbsolutePath);
            var availableGb = stat.AvailableBytes / 1024d / 1024d / 1024d;
            var totalGb = stat.TotalBytes / 1024d / 1024d / 1024d;
            lines.Add($"{(_isRussian ? "Свободное хранилище" : "Free storage")}: {availableGb:0.0} / {totalGb:0.0} GB");
        }
        catch
        {
            lines.Add(_isRussian ? "Хранилище: данные недоступны" : "Storage: unavailable");
        }

        try
        {
            var manager = Android.App.Application.Context.GetSystemService(Context.ActivityService) as ActivityManager;
            var memory = new ActivityManager.MemoryInfo();
            manager?.GetMemoryInfo(memory);
            if (manager is not null)
            {
                var availableRam = memory.AvailMem / 1024d / 1024d / 1024d;
                var totalRam = memory.TotalMem / 1024d / 1024d / 1024d;
                lines.Add($"{(_isRussian ? "Доступная ОЗУ" : "Available system RAM")}: {availableRam:0.0} / {totalRam:0.0} GB");
                lines.Add($"{(_isRussian ? "Низкий запас памяти" : "Low-memory state")}: {(memory.LowMemory ? (_isRussian ? "да" : "yes") : (_isRussian ? "нет" : "no"))}");
            }
        }
        catch
        {
            lines.Add(_isRussian ? "ОЗУ: данные недоступны" : "RAM: unavailable");
        }
#endif

        lines.Add($"{(_isRussian ? "Выбранное приложение" : "Selected app")}: {(string.IsNullOrWhiteSpace(selectedGame) ? (_isRussian ? "не выбрано" : "none") : selectedGame)}");
        return string.Join("\n", lines);
    }

    private void OnRussianClicked(object sender, EventArgs e)
    {
        _isRussian = true;
        Preferences.Set("app_language", "ru");
        ApplyLanguage();
    }

    private void OnEnglishClicked(object sender, EventArgs e)
    {
        _isRussian = false;
        Preferences.Set("app_language", "en");
        ApplyLanguage();
    }

    private void ApplyLanguage()
    {
        TitleLabel.Text = "BOOST";
        StatusLabel.Text = _isRussian ? "ГОТОВО" : "READY";
        SubtitleLabel.Text = _isRussian ? "Помощник игровой производительности" : "Gaming performance companion";
        DeviceHeading.Text = _isRussian ? "СОСТОЯНИЕ УСТРОЙСТВА" : "DEVICE STATUS";
        OsTitleLabel.Text = _isRussian ? "СИСТЕМА" : "SYSTEM";
        RamTitleLabel.Text = _isRussian ? "ПАМЯТЬ ПРОЦЕССА" : "APP MEMORY";
        DeviceNoteLabel.Text = _isRussian
            ? "Показываются только данные, доступные приложению."
            : "Only data available to the app is shown.";
        BoostButton.Text = _isRussian ? "ЗАПУСТИТЬ SMART BOOST" : "RUN SMART BOOST";
        DiagnosticsTitleLabel.Text = _isRussian ? "Диагностика" : "Diagnostics";
        DiagnosticsDescLabel.Text = _isRussian ? "Реальные данные устройства" : "Live device information";
        GamesTitleLabel.Text = _isRussian ? "Игры и приложения" : "Games & apps";
        GamesDescLabel.Text = _isRussian ? "Выбрать и запустить приложение" : "Choose and launch an app";
        DiagnosticsButton.Text = _isRussian ? "ПРОВЕРИТЬ" : "CHECK";
        GamesButton.Text = _isRussian ? "ОТКРЫТЬ" : "OPEN";
        LaunchSelectedGameButton.Text = _isRussian ? "ЗАПУСТИТЬ ИГРУ" : "LAUNCH GAME";
        SelectedGameSettingsButton.Text = _isRussian ? "ПРОФИЛЬ ИГРЫ" : "GAME PROFILE";
        var selectedGameName = Preferences.Get("selected_game_name", "");
        SelectedGameActions.IsVisible = !string.IsNullOrWhiteSpace(selectedGameName);
        if (!string.IsNullOrWhiteSpace(selectedGameName))
            GamesDescLabel.Text = (_isRussian ? "Выбрано: " : "Selected: ") + selectedGameName;
        UpdateGameProfileSummary();
        SettingsTitleLabel.Text = _isRussian ? "НАСТРОЙКИ" : "SETTINGS";
        LanguageLabel.Text = _isRussian ? "Язык интерфейса" : "Interface language";
        FooterLabel.Text = _isRussian ? "NEBULA BOOST • РАБОЧИЙ ПРОТОТИП" : "NEBULA BOOST • FUNCTIONAL PROTOTYPE";

        RuButton.BackgroundColor = _isRussian ? Color.FromArgb("#FF4B32") : Color.FromArgb("#252B36");
        EnButton.BackgroundColor = !_isRussian ? Color.FromArgb("#FF4B32") : Color.FromArgb("#252B36");
    }
}
