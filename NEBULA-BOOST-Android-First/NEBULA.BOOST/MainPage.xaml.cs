using Microsoft.Maui.ApplicationModel;
using Microsoft.Maui.Devices;
using Microsoft.Maui.Storage;

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
        // This is process memory, not total device RAM. Label is explicit to avoid fake telemetry.
        var processMb = GC.GetTotalMemory(false) / (1024d * 1024d);
        RamValueLabel.Text = $"{processMb:0} MB";
    }

    private async void OnBoostClicked(object sender, EventArgs e)
    {
        var title = _isRussian ? "Проверка готова" : "Smart check";
        var message = _isRussian
            ? "Базовая проверка приложения завершена. Автоматическое изменение FPS или системных параметров недоступно без поддержки ОС и производителя."
            : "Basic app check completed. Changing FPS or system settings automatically requires operating-system and manufacturer support.";
        await DisplayAlert(title, message, _isRussian ? "Понятно" : "OK");
    }

    private async void OnDiagnosticsClicked(object sender, EventArgs e)
    {
        var title = _isRussian ? "Диагностика" : "Diagnostics";
        var message = _isRussian
            ? $"Модель: {DeviceInfo.Current.Model}\nПлатформа: {DeviceInfo.Current.Platform}\nВерсия: {DeviceInfo.Current.VersionString}\n\nТемпература и частота кадров пока не доступны через универсальный API."
            : $"Model: {DeviceInfo.Current.Model}\nPlatform: {DeviceInfo.Current.Platform}\nVersion: {DeviceInfo.Current.VersionString}\n\nTemperature and FPS are not yet available through a universal API.";
        await DisplayAlert(title, message, _isRussian ? "Закрыть" : "Close");
    }

    private async void OnGamesClicked(object sender, EventArgs e)
    {
        await DisplayAlert(_isRussian ? "Мои игры" : "My Games",
            _isRussian
                ? "Раздел игровых профилей будет подключён следующим этапом. Приложение не будет заявлять, что меняет настройки игр без реального доступа."
                : "Game profiles will be implemented in the next stage. The app will not claim to change game settings without actual access.",
            _isRussian ? "Понятно" : "OK");
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
        TitleLabel.Text = _isRussian ? "BOOST" : "BOOST";
        StatusLabel.Text = _isRussian ? "ГОТОВО" : "READY";
        SubtitleLabel.Text = _isRussian ? "Помощник игровой производительности" : "Gaming performance companion";
        DeviceHeading.Text = _isRussian ? "СОСТОЯНИЕ УСТРОЙСТВА" : "DEVICE STATUS";
        OsTitleLabel.Text = _isRussian ? "СИСТЕМА" : "SYSTEM";
        RamTitleLabel.Text = _isRussian ? "ПАМЯТЬ ПРОЦЕССА" : "APP MEMORY";
        DeviceNoteLabel.Text = _isRussian
            ? "Показываются только данные, доступные приложению."
            : "Only data available to the app is shown.";
        BoostButton.Text = _isRussian ? "ЗАПУСТИТЬ ПРОВЕРКУ" : "RUN SMART CHECK";
        DiagnosticsTitleLabel.Text = _isRussian ? "Диагностика" : "Diagnostics";
        DiagnosticsDescLabel.Text = _isRussian ? "Проверка доступных данных" : "Check supported device data";
        GamesTitleLabel.Text = _isRussian ? "Мои игры" : "My Games";
        GamesDescLabel.Text = _isRussian ? "Игровые профили и советы" : "Game profiles and tips";
        DiagnosticsButton.Text = _isRussian ? "ОТКРЫТЬ" : "OPEN";
        GamesButton.Text = _isRussian ? "ОТКРЫТЬ" : "OPEN";
        SettingsTitleLabel.Text = _isRussian ? "НАСТРОЙКИ" : "SETTINGS";
        LanguageLabel.Text = _isRussian ? "Язык интерфейса" : "Interface language";
        FooterLabel.Text = _isRussian ? "NEBULA BOOST • РАННЯЯ ВЕРСИЯ" : "NEBULA BOOST • EARLY BUILD";

        RuButton.BackgroundColor = _isRussian ? Color.FromArgb("#FF4B32") : Color.FromArgb("#252B36");
        EnButton.BackgroundColor = !_isRussian ? Color.FromArgb("#FF4B32") : Color.FromArgb("#252B36");
    }
}
