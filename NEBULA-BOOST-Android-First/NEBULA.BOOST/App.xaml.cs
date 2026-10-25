namespace NebulaBoost;

public partial class App : Application
{
    public App()
    {
        InitializeComponent();
        MainPage = new NavigationPage(new MainPage())
        {
            BarBackgroundColor = Color.FromArgb("#090B0F"),
            BarTextColor = Colors.White
        };
    }
}
