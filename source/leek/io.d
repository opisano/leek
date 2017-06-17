/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Copyright 2017 Olivier Pisano.
    This file is part of Leek.

    Leek is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Leek is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

module leek.io;

/**
 * Presents an interface for user dialog.
 */
interface IO
{
    /**
     * Displays a message to the user.
     */
    void display(string message);

    /**
     * Prompt the user to enter an input.
     *
     * Params:
     *     prompt = The prompt text.
     *
     * Returns:
     *     The text entered by the user.
     */
    string input(string prompt);

    /**
     * Prompt the user to enter an input, without echoing the text entered.
     * 
     * Params:
     *     prompt = The prompt text.
     *
     * Returns:
     *     The text entered by the user.
     */
    string input_password(string prompt);
}

version (linux)
{
    import core.sys.linux.termios;
    import core.sys.linux.unistd;

    import std.stdio;

    IO getIO()
    {
        return new LinuxConsoleIO;
    }

    /**
     * User interface for linux console.
     */
    class LinuxConsoleIO : IO
    {
    public:
        this()
        {
            buffer = new char[1024];
        }

        override void display(string message)
        {
            stdout.write(message);
        }

        override string input(string prompt)
        {
            stdout.write(prompt);
            size_t len = stdin.readln(buffer);
            return buffer[0 .. len].idup;
        }

        override string input_password(string prompt)
        {
            stdout.write(prompt);

            // save terminal flags
            termios oldFlags = getTerminalFlags();
            
            // disable echo
            auto currentFlags = oldFlags;
            disableEcho(currentFlags);
            setTerminalFlags(currentFlags);

            // reactivate echo at exit
            scope (exit)
                setTerminalFlags(oldFlags);

            // Read line
            size_t len = stdin.readln(buffer);
            return buffer[0 .. len].idup;
        }

    private:

        /**
         * Returns the terminal flags.
         */
        static termios getTerminalFlags()
        {
            termios flags;
            if (tcgetattr(STDIN_FILENO, &flags) != 0)
                throw new StdioException("Cannot get terminal flags.");

            return flags;
        }

        /**
         * Sets the terminal flags.
         */
        static void setTerminalFlags(ref termios flags)
        {
            if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &flags) != 0)
                throw new StdioException("Cannot set terminal flags.");
        }

        /**
         * Flips the terminal echo flags.
         */
        static void disableEcho(ref termios flags)
        {
            flags.c_lflag &= ~ECHO;
        }

        /// line buffer
        char[] buffer;
    }

    IO createIO()
    {
        return new LinuxConsoleIO();
    }
}

