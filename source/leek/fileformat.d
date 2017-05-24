/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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

module leek.fileformat;

import leek.leek;

/**
 * Signals a file format is not supported.
 */
class UnsupportedFileFormatException : Exception
{
    public this(string message)
    {
        super(message);
    }
}


/**
 * Provides the interface for reading the passwords from a file. 
 */
interface FileReader
{
    /**
     * Reads a file and returns an AccountManager object for the 
     * file content.
     *
     * Params:
     *     filename = The path to the file to open. 
     */
    AccountManager readFromFile(string filename);
}


/**
 * Provides the interface for writing the passwords to a file.
 */
interface FileWriter
{
    void writeToFile(AccountManager manager, string filename);
}


/**
 * Provides the interface for creating the file format I/O objects.
 */
class FileFormatFactory
{
    /**
     * Create a FileReader object for the file format passed as a parameter.
     */
    FileReader createReader(string format)
    {
        return null;
    }

    /**
     * Create a FileWriter object for the file format passed as a parameter.
     */
    FileWriter createWriter(string format)
    {
        if (format == "leek")
            return new LeekWriter;

        throw new UnsupportedFileFormatException(format); 
    }
}


class LeekWriter : FileWriter
{
    override void writeToFile(AccountManager manager, string filename)
    {

    }
}


