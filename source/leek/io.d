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

import std.typecons;

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
    string inputPassword(string prompt);
}

alias SilentIO = BlackHole!IO;

version (linux)
{
    import core.sys.linux.termios;
    import core.sys.linux.unistd;
    import core.stdc.stdlib;

    import gnu.readline;

    import std.stdio;
    import std.string;

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
        override void display(string message)
        {
            stdout.write(message);
        }

        override string input(string prompt)
        {
            char* line = readline(prompt.toStringz);
            scope (exit)
                free(line);
            return line.fromStringz.idup;
        }

        override string inputPassword(string prompt)
        {
            //stdout.write(prompt);

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
            //size_t len = stdin.readln(buffer);
            //return buffer[0 .. len].idup;
            return input(prompt);
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
    }

    IO createIO()
    {
        return new LinuxConsoleIO();
    }
}


version(unittest)
{
    /**
     * IO implementation that always returns the same values. for testing purposes.
     */
    class TestIO : IO
    {
        this(string inputResponse, string inputPasswordResponse)
        {
            m_inputResponse = inputResponse;
            m_inputPasswordResponse = inputPasswordResponse;
        }

        override void display(string message)
        {
            m_output ~= message;
        }

        override string input(string prompt)
        {
            return m_inputResponse;
        }

        override string inputPassword(string prompt)
        {
            return m_inputPasswordResponse;
        }
        
        string[] output() 
        {
            return m_output;
        }

    private:
        string[] m_output;
        string   m_inputResponse; 
        string   m_inputPasswordResponse;
    }
}
