package login;

import base.BaseTest;
import org.openqa.selenium.By;
import org.testng.Assert;
import org.testng.annotations.Test;
import org.testng.annotations.Listeners;
import listeners.TestFailureListener;

@Listeners(TestFailureListener.class)
public class LoginTest extends BaseTest {

    @Test
    public void invalidLoginTest() {

        driver.get("https://the-internet.herokuapp.com/login");

        driver.findElement(By.id("username")).sendKeys("wrongUser");
        driver.findElement(By.id("password")).sendKeys("wrongPass");
        driver.findElement(By.cssSelector("button[type='submit']")).click();

        String error = driver.findElement(By.id("flash")).getText();

        Assert.assertTrue(error.contains("Your username is invalid!"));
    }
}