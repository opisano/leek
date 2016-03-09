/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    This file is part of Leek.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

module leek.mainwindow;

import gtk.ApplicationWindow;
import gtk.Builder;
import gtk.Main;
import gtk.Widget;

import std.exception;

private enum mainWindowCode = import("leek/mainwindow.glade");

/**
 * The controller class of our main window. 
 */
class MainWindowController
{
private:
    Builder view;
    ApplicationWindow window;

    /**
     * Handles onHide event.
     */
    void onHide(Widget aux)
    {
        Main.quit();
    }

    /** 
     * Initializes the view components of this class.
     */
    void initializeView()
    {
        view = new Builder;
        view.addFromString(mainWindowCode);
        window = cast(ApplicationWindow) view.getObject("mainWindow");
        enforce(window !is null);

        window.addOnHide(&onHide);
        window.showAll();
    }

public:
    this()
    {
        initializeView();
    }
}
