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

import botan.libstate.lookup;
import botan.passhash.bcrypt;
import botan.pbkdf.pbkdf;
import botan.rng.auto_rng;

import leek.account;

import std.algorithm;
import std.array;
import std.bitmanip;
import std.range;
import std.stdio;

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

/+
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
}+/


class LeekWriter: FileWriter
{
public:
    this(string masterPassword)
    {
        this.masterPassword = masterPassword;
    }

    override void writeToFile(AccountManager manager, string filename)
    {
        auto f = File(filename, "wb");
        f.write(signatureAndVersion());
        f.write(hashedPassword());
        auto salt = generateSalt();
        f.write(salt);
        auto key = generateKey(salt);
        // TODO serialize and encrypt manager content.
    }

private:

    /**
     * Return the signature and version of the file format.
     */ 
    ubyte[] signatureAndVersion()
    {
        return cast(ubyte[])['L', 'E', 'E', 'K',
                              0, 0, 0, 1];
    }

    unittest
    {
        auto lw = new LeekWriter("password123");
        auto result = lw.signatureAndVersion();
        assert (result.equal(cast(ubyte[])[76, 69, 69, 75, 0, 0, 0, 1]));
    }

    /**
     * Salt and hash the master password
     */
    string hashedPassword()
    {
        auto rng = new AutoSeededRNG;
        string result = generateBcrypt(masterPassword, rng, 10);
        return result;
    }

    unittest
    {
        auto lw = new LeekWriter("password123");
        string result = lw.hashedPassword();
        assert (checkBcrypt("password123", result));
    }

    ubyte[] generateSalt()
    {
        auto rng = new AutoSeededRNG;
        auto salt = new ubyte[64];
        rng.randomize(salt.ptr, salt.length);
        return salt;
    }

    /**
     * Generate an AES256 key from master password and 
     * some salt.
     *
     * Params:
     *     salt = The salt to use
     *
     * Returns:
     *     The AES-256 key from master password and salt.
     */
    auto generateKey(ubyte[] salt)
    {
        PBKDF pbkdf = getPbkdf("PBKDF2(SHA-512)");
        auto rng = new AutoSeededRNG;
        auto aes256_key = pbkdf.deriveKey(32, masterPassword,
                                          salt.ptr, salt.length,
                                          10_000);
        return aes256_key;
    } 

    /**
     * Encodes a CategoryRecord as an InputRange of ubyte.
     */
    static auto encodeCategoryRecord(CategoryRecord record) pure
    {
        enum category = 0xCA1E6074;
        return chain(encodeInteger(category),
                     encodeInteger(record.id),
                     encodeString(record.name));
    }

    unittest 
    {
        auto cat = CategoryRecord(0x42, "Music");
        assert (equal(encodeCategoryRecord(cat),
                      [0x74, 0x60, 0x1E, 0xCA, 
                       0x42, 0x00, 0x00, 0x00,
                       0x05, 0x00, 0x00, 0x00,
                       0x4d, 0x75, 0x73, 0x69, 0x63]));
    }

    /**
     * Encodes an AccountRecord as an InputRange of ubyte.
     */
    static auto encodeAccountRecord(AccountRecord record) pure
    {
        enum account = 0xACC0947;
        return chain(encodeInteger(account),
                     encodeString(record.name),
                     encodeString(record.login),
                     encodeString(record.password),
                     encodeInteger(cast(uint)record.categories.length),
                     joiner(record.categories.map!(x => encodeInteger(x))));
    }

    unittest 
    {
        auto acc = AccountRecord("Netflix", "JohnDoe", "password",
                                 [0x13, 0x18]);
        assert (equal(encodeAccountRecord(acc),
                      [0x47, 0x09, 0xCC, 0x0A, 
                       0x07, 0x00, 0x00, 0x00,
                       0x4e, 0x65, 0x74, 0x66, 0x6c, 0x69, 0x78,
                       0x07, 0x00, 0x00, 0x00,
                       0x4a, 0x6f, 0x68, 0x6e, 0x44, 0x6f, 0x65,
                       0x08, 0x00, 0x00, 0x00,
                       0x70, 0x61, 0x73, 0x73, 0x77, 0x6f, 0x72, 0x64,
                       0x02, 0x00, 0x00, 0x00,
                       0x13, 0x00, 0x00, 0x00,
                       0x18, 0x00, 0x00, 0x00]));
    }

    /**
     * Encodes a uint as an InputRange of ubyte, in little endian 
     * order.
     */
    static auto encodeInteger(uint n) pure
    {
        struct IntRange
        {
            uint value;
            uint count = 0;
            bool empty() const { return count > 3; }
            ubyte front() const { return (value >> (count * 8)) & 0xFF; }
            void popFront() { count++; }
        }

        return IntRange(n);
    }

    unittest 
    {
        assert (equal(encodeInteger(0xDEADBEEF),
                      [0xEF, 0xBE, 0xAD, 0xDE]));
    }

    /**
     * Encodes a string as an InputRange of ubyte.
     */
    static auto encodeString(string s) pure
    {
        if (s.length > uint.max)
            s = s[0 .. uint.max];

        return chain(encodeInteger(cast(uint)s.length),
                     cast(ubyte[])s.dup);
    }

    unittest 
    {
        assert (equal(encodeString("ABBA"),
                      [0x04, 0x00, 0x00, 0x00, 0x41, 0x42, 0x42, 0x41]));
    }

    immutable string masterPassword;
}


