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
import std.exception;
import std.path;
import std.range;
import std.stdio;
import std.traits;

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
 * Signals the master password is incorrect.
 */
class WrongPasswordException : Exception
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
 *
 * Params:
 *     manager = contains the passwords and categories to write.
 *     filename = the name of the file to write. 
 */
interface FileWriter
{
    /**
     * Writes the content of an AccountManager to a file.
     *
     * The AccountManager instance passed as first parameter must 
     * be a LeekAccountManager, or an UnsupportedFileFormatException
     * will be thrown.  
     *
     * Params:
     *     manager = contains the passwords and categories to write.
     *     filename = the name of the file to write. 
     * 
     * Throws:
     *     UnsupportedFileFormatException if manager is not a 
     *     LeekAccountManager.
     */
    void writeToFile(AccountManager manager, string filename);
}


/**
 * Implementation of the FileReader interface for the Leek 1 
 * file format. 
 */
class LeekReader : FileReader
{
    /**
     * Create a LeekReader.
     *
     * Params:
     *     masterPassword = the master password.
     */ 
    this(string masterPassword)
    {
        this.masterPassword = masterPassword;
    }

    public override AccountManager readFromFile(string filename)
    {
        auto f = File(filename, "rb");
        if (!readFormatAndVersion(f))
        {
            throw new UnsupportedFileFormatException("Unknown format");
        }
        
        if (!checkPassword(f))
        {
            throw new WrongPasswordException("incorrect password");
        }

        auto salt = readSalt(f);
        auto key = generateKey(salt, masterPassword);
        ubyte[256] buffer;
        auto iv = readIV(f);
        auto pipe = botan.filters.pipe.Pipe(getCipher("AES-256/CBC", 
                                            generateKey(salt, masterPassword),
                                            iv,
                                            DECRYPTION));

        auto bytesRead = f.rawRead(buffer[]);
        pipe.startMsg();
        while (bytesRead.length)
        {
            pipe.write(bytesRead);
            bytesRead = f.rawRead(buffer[]);
        }
        pipe.endMsg();
        auto data = cast(immutable(ubyte)[])pipe.toString();
        auto mgr = new LeekAccountManager;
        decodeCategories(data, mgr);
        decodeAccounts(data, mgr);

        return mgr;
    }

private:
    static bool readFormatAndVersion(ref File f)
    {
        ubyte[8] buffer;
        auto bytesRead = f.rawRead(buffer[]);
        return buffer[] == [76, 69, 69, 75, 0, 0, 0, 1];
    }

    /**
     * Reads the master password hash from the file and returns 
     * true if it corresponds to this object master password, 
     * false otherwise.
     * 
     * Params:
     *     f = An open file to read data from.
     *
     * Returns:
     *     true if the master password and the hash match, false otherwise.
     */ 
    bool checkPassword(ref File f)
    {
        ubyte[60] buffer;
        auto bytesRead = f.rawRead(buffer[]);
        return checkBcrypt(masterPassword, cast(string)bytesRead);
    }

    /**
     * Reads the secret key salt from the file. 
     *
     * Params:
     *     f = An open file to read data from.
     *
     * Returns:
     *     Some random bytes, used for salt for the secret key.
     */
    ubyte[] readSalt(ref File f)
    {
        return f.rawRead(new ubyte[64]);
    }

    /**
     * Reads the Intialization vector from the file.
     * 
     * Params:
     *     f = An open file to read data from.
     *
     * Returns:
     *     Some random bytes, read from the file, used as initialization vector.
     */
    auto readIV(ref File f)
    {
        ubyte[16] buffer;
        auto iv = f.rawRead(buffer[0 .. 16]);
        if (iv.length != 16)
            throw new StdioException("Missing data.");
        return OctetString(iv.ptr, iv.length);
    }

    /**
     * Decodes all the categories from decrypted raw data.
     * 
     * Params:
     *     r = an input range of ubytes, as data source.
     *     mgr = an AccountManager that will store the decoded categories.
     * 
     * Throws:
     *     StdioException if runs out of data in the middle of a Category.
     */
    static void decodeCategories(R)(ref R r, LeekAccountManager mgr)
            if (isInputRange!R && is(ubyte == Unqual!(ElementType!R)))
    {
        enum category_id = 0xCA1E6074;
        while (!r.empty && decodeInteger(take(r, 4)) == category_id)
        {
            auto cat = decodeCategory(r);
            mgr.addCategory(cat.name);
        }
    }

    /**
     * Decodes all the accounts from decrypted raw data.
     * 
     * Params:
     *     r = an input range of ubytes, as data source.
     *     mgr = an AccountManager that will store the decoded accounts.
     * 
     * Throws:
     *     StdioException if runs out of data in the middle of an Account.
     */
    static void decodeAccounts(R)(ref R r, LeekAccountManager mgr)
            if (isInputRange!R && is(ubyte == Unqual!(ElementType!R)))
    {
        enum account_id = 0xACC0947;
        while (!r.empty && decodeInteger(take(r, 4)) == account_id)
        {
            auto record = decodeAccount(r);
            mgr.addAccount(record);
        }
    }

    /**
     * Decode an Account from an input range of ubytes.
     *
     * Params:
     *     r = The range as data source
     *
     * Returns:
     *     An AccountRecord object containing raw account data.
     *
     * Throws StdioException if run out of data while decoding.
     */
    static AccountRecord decodeAccount(R)(ref R r)
            if (isInputRange!R && is(ubyte == Unqual!(ElementType!R)))
    {
        r = r.drop(uint.sizeof); // skip AccountRecord identifier.
        auto name = decodeString(r);
        auto login = decodeString(r);
        auto password = decodeString(r);
        auto cat_count = decodeInteger(r);
        uint[] ids;
        foreach (i; 0 .. cat_count)
        {
            ids ~= decodeInteger(r);
        }
        return AccountRecord(name, login, password, ids);
    }

    unittest
    {
        ubyte[] arr = cast(ubyte[])[0x47, 0x09, 0xCC, 0x0A, 
                                    0x07, 0x00, 0x00, 0x00,
                                    0x4e, 0x65, 0x74, 0x66, 0x6c, 0x69, 0x78,
                                    0x07, 0x00, 0x00, 0x00,
                                    0x4a, 0x6f, 0x68, 0x6e, 0x44, 0x6f, 0x65,
                                    0x08, 0x00, 0x00, 0x00,
                                    0x70, 0x61, 0x73, 0x73, 
                                    0x77, 0x6f, 0x72, 0x64,
                                    0x02, 0x00, 0x00, 0x00,
                                    0x13, 0x00, 0x00, 0x00,
                                    0x18, 0x00, 0x00, 0x00];
        auto ar = decodeAccount(arr);
        assert (ar.name == "Netflix");
        assert (ar.login == "JohnDoe");
        assert (ar.password == "password");
        assert (ar.categories == [0x13, 0x18]);
    }

    /**
     * Decode a Category from an input range of ubytes.
     *
     * Params:
     *     r = The range as data source
     *
     * Returns:
     *     A Category object containing raw category data.
     *
     * Throws StdioException if run out of data while decoding.
     */
    static CategoryRecord decodeCategory(R)(ref R r)
            if (isInputRange!R && is(ubyte ==  Unqual!(ElementType!R)))
    {
        r = r.drop(uint.sizeof); // skip CategoryRecord identifier.
        uint id = decodeInteger(r);
        string name = decodeString(r);
        return CategoryRecord(id, name);
    }

    unittest 
    {
        auto arr = cast(ubyte[])[0x74, 0x60, 0x1E, 0xCA, 
                                 0x42, 0x00, 0x00, 0x00,
                                 0x05, 0x00, 0x00, 0x00,
                                 0x4d, 0x75, 0x73, 0x69, 0x63];
        auto cat = decodeCategory(arr);
        assert(cat.id == 0x42);
        assert(cat.name == "Music");
        assert(arr.empty);
    }

    /**
     * Decodes a string from an InputRange of ubyte 
     */
    static string decodeString(R)(ref R r)
            if (isInputRange!R && is(ubyte == Unqual!(ElementType!R)))
    {
        uint length = decodeInteger(r);
        char[] buffer = cast(char[])r.take(length).array;
        r = r.drop(length);
        return assumeUnique(buffer);
    }

    unittest
    {
        ubyte[] arr = cast(ubyte[])[0x04, 0x00, 0x00, 0x00, 
                                    0x41, 0x42, 0x42, 0x41,
                                    0x04, 0x00, 0X00, 0x00, 
                                    0x54, 0x4F, 0x54, 0x4F];
        assert(decodeString(arr) == "ABBA");
        assert(decodeString(arr) == "TOTO");
    }

    /**
     * Decodes an integer from an Input range of ubyte.
     */
    static uint decodeInteger(R)(auto ref R r)
            if (isInputRange!R && is(ubyte == Unqual!(ElementType!R)))
    {
        uint result;
        foreach (i; 0 .. 4)
        {
            if (r.empty)
                throw new StdioException("Missing data");
            result |= r.front << (i * 8);
            r.popFront;
        }
        return result;
    }

    unittest
    {
        ubyte[] arr = [0xBE, 0xBA, 0xFE, 0xCA,
                       0xEF, 0xBE, 0xAD, 0xDE,
                       0xCA, 0xCA];
        assert (decodeInteger(arr) == 0xCAFEBABE);
        assert (decodeInteger(arr) == 0xDEADBEEF);
        assertThrown!StdioException(decodeInteger(arr));
    }

    string masterPassword;
}

/**
 * A FileWriter Factory Method. 
 */
interface FileWriterFactory
{
    /**
     * Creates a FileWriter. 
     *
     * Params:
     *     masterPassword = The master password to use to write the file.
     *
     * Returns a FileWriter object to write to the file. 
     */
    FileWriter createFileWriter(string masterPassword);
}

/**
 * Creates FileWriter objects for the Leek 1 file format.
 */
class LeekFactory : FileWriterFactory, FileReaderFactory
{
    public override FileWriter createFileWriter(string masterPassword)
    {
        return new LeekWriter(masterPassword);
    }
    
    public override FileReader createFileReader(string masterPassword)
    {
        return new LeekReader(masterPassword);
    }
}

/**
 * A FileReader Factory Method.
 */
interface FileReaderFactory
{
    /**
     * Creates a FileReader. 
     *
     * Params:
     *     masterPassword = The master password to use to read the file.
     *
     * Returns a FileReader object to read the file. 
     */
    FileReader createFileReader(string masterPassword);
}

/**
 * Returns a FileWriterFactory to the latest native leek format.
 */
FileWriterFactory latestWriterFormat()
{
    return new LeekFactory();
}

/**
 * Returns a FileReaderFactory to the latest native leek format.
 */
FileReaderFactory latestReaderFormat()
{
    return new LeekFactory();
}

/**
 * Implementation of the FileWriter interface for the Leek 1
 * file format.
 */
class LeekWriter: FileWriter
{
public:

    /**
     * Constructs a LeekWriter instance.
     *
     * Params:
     *     masterPassword = The master password from which secret keys
     *                      will be derived to encrypt files written.
     */
    this(string masterPassword)
    {
        this.masterPassword = masterPassword;
    }

    override void writeToFile(AccountManager manager, string filename)
    {
        auto mgr = cast(LeekAccountManager) manager;
        if (mgr is null)
        {
            throw new UnsupportedFileFormatException("Incorrect manager");
        }

        auto f = File(filename, "wb");
        f.rawWrite(signatureAndVersion());
        f.rawWrite(hashedPassword());
        auto salt = generateSalt();
        f.rawWrite(salt);
        auto iv = InitializationVector(new AutoSeededRNG, 16);
        f.rawWrite(iv.bitsOf()[]);
        auto pipe = botan.filters.pipe.Pipe(getCipher("AES-256/CBC", 
                                            generateKey(salt, masterPassword), 
                                            iv, 
                                            ENCRYPTION));
        auto data = encodeAccountManager(mgr).array();

        pipe.startMsg();
        pipe.write(data.ptr, data.length);
        pipe.endMsg();
        f.rawWrite(pipe.toString());
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
     * Encodes the content of a LeekAccountManager as a stream of 
     * bytes.
     */ 
    static auto encodeAccountManager(LeekAccountManager mgr) pure
    {
        return chain(mgr.categoryRecords
                        .map!(cr => encodeCategoryRecord(cr))
                        .joiner,
                     mgr.accountRecords
                        .map!(ar => encodeAccountRecord(ar))
                        .joiner);
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
            immutable(ubyte) front() const { return (value >> (count * 8)) & 0xFF; }
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
                     cast(immutable(ubyte)[])s);
    }

    unittest 
    {
        assert (equal(encodeString("ABBA"),
                      [0x04, 0x00, 0x00, 0x00, 0x41, 0x42, 0x42, 0x41]));
    }

    immutable string masterPassword;
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
auto generateKey(ubyte[] salt, string masterPassword)
{
    PBKDF pbkdf = getPbkdf("PBKDF2(SHA-512)");
    auto rng = new AutoSeededRNG;
    auto aes256_key = pbkdf.deriveKey(32, masterPassword,
                                      salt.ptr, salt.length,
                                      10_000);
    return aes256_key;
}

unittest 
{
    import botan.all;
    import std.file; 
    
    LibraryInitializer init;
    init.initialize();

    auto man = createAccountManager();
    auto cat = man.addCategory("Entertainment");
    auto acc = man.addAccount("Netflix", "johndoe", "password123");
    acc.addCategory(cat);
    auto filewriter = new LeekWriter("mysecret");

    auto tempfilename = buildPath(tempDir(), "leek_test.bin");
    filewriter.writeToFile(man, tempfilename);
    scope (exit)
    {
        if (tempfilename.exists)
            tempfilename.remove;
    }

    auto filereader = new LeekReader("mysecret");
    auto man2 = filereader.readFromFile(tempfilename);
    auto cat2 = take(man2.categories(), 1).front;
    assert (cat2.name == "Entertainment");
    auto acc2 = man2.getAccount("Netflix");
    assert (acc2.name == "Netflix");
    assert (acc2.login == "johndoe");
    assert (acc2.password == "password123");
    assert (acc2.categories.front.name == "Entertainment");
}

version (linux)
{
    import core.sys.posix.unistd;
    import core.sys.posix.sys.types;
    import core.sys.posix.pwd;
    import std.process;

    /**
     * Returns the filename where the password database is stored.
     */
    string databaseFilename() 
    {
        return buildPath(getUserDataDir(),
                         "leek",
                         "data.bin");
    }

    /**
     * Returns the base directory relative to which user specific data files
     * should be stored. This function conforms to the freedesktop base
     * directory specification.
     * 
     * See_Also:
     *     https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
     */
    private string getUserDataDir()
    {
        string xdg_data_home = std.process.environment.get("XDG_DATA_HOME");
        if (xdg_data_home is null || !isAbsolute(xdg_data_home))
            xdg_data_home = buildPath(getHomeDir(), 
                                      ".local",
                                      "share");
        return xdg_data_home;
    }

    /**
     * Returns the user home directory.
     */
    private string getHomeDir()
    {
        auto pw = getpwuid(getuid());
        const(char)* homedir = pw.pw_dir;
        return homedir.to!string;
    }
}
