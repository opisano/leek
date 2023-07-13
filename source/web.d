module web;

import vibe.vibe;
import std.experimental.logger;

class WebInterface
{
    // GET /
    void index()
    {
        bool authenticated = ms_authenticated;
        if (!authenticated)
        {
            info("Not authenticated, display login form");
            render!("index.dt");
        }
        else
        {
            info("Authenticated, display home page");
            render!("home.dt");
        }
    }

    void login(string uname, string psw)
    {
        /*if (system.checkPassword(uname, psw))
        {
            info("Password is valid");
            ms_authenticated = true;
            
        }
        else 
        {
            info("Password is invalid");
        }*/
        redirect("/");
    }

private:
    SessionVar!(bool, "authenticated") ms_authenticated;
}
