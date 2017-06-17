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

module leek.validate;

import leek.io;
import std.algorithm;
import std.ascii;


/**
 * Checks that a password is reasonably valid.
 *
 * Params:
 *     password = the password to check.
 *     io       = A IO object to to interact with the user.
 *
 * Returns:
 *     true if the password is considered valid, false otherwise.
 */
bool validatePassword(string password, IO io)
{
    // TODO consider user libcrack to check this. 

    enum MIN_PASSWORD_LENGTH = 12;
    bool valid = true;

    if (password.length < MIN_PASSWORD_LENGTH)
    {
        io.display("Password is too short\n");
        valid = false;
    }

    if (!password.canFind!(c => c.isUpper))
    {
        io.display("Password does not contain uppercase letters\n");
        valid = false;
    }

    if (!password.canFind!(c => c.isLower))
    {
        io.display("Password does not contain lowercase letters\n");
        valid = false;
    }

    if (!password.canFind!(c => c.isDigit))
    {
        io.display("Password does not contain digits\n");
        valid = false;
    }

    return valid;
}

