Add-Type -Path "PATH_TO_WebDriver.dll"

using OpenQA.Selenium;
using OpenQA.Selenium.Edge;

# UA String
$userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/110.0"

# create EdgeOptions object with custom user agent
$options = New-Object OpenQA.Selenium.Edge.EdgeOptions
$options.AddAdditionalCapability("ms:edgeChromium", $true)
$options.AddArgument("--user-agent=" + $userAgent)
$options.AddArgument("--headless")

# create EdgeDriver with custom options
$driver = New-Object OpenQA.Selenium.Edge.EdgeDriver($options)

# navigate to URL
$driver.Navigate().GoToUrl("https://www.example.com/login")

# find and fill in username/password fields
$username = $driver.FindElementByXPath('//*[@id="login_field"]')
$username.SendKeys("USERNAME")
$password = $driver.FindElementByXPath('//*[@id="password"]')
$password.SendKeys("PASSWORD")

# Submit the login form
$form = $driver.FindElementByXPath('//*[@name="commit"]')
$form.Submit()

# Quit the driver
$driver.Quit()
