import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass, autoclass

NSString = None
N = lambda x: NSString().initWithUTF8String_(x)

class NSObject(unittest.TestCase):

    def setUp(self):
        global NSString
        NSString = autoclass('NSString')

    def test_utf8(self):
        s = u'\x09cole'
        text = N(s)
        self.assertTrue(text.cString() == s)

    def test_length(self):
        self.assertEquals(N('hello').length(), 5)

    '''
    # TODO the returned class of initWithUTF8String_ deosn't have the
    # required method for theses tests
    def test_lengthEncoding(self):
        s = u'\xe9cole'
        #self.assertEquals(N(s.encode('utf8')).lengthOfBytesUsingEncoding_(1), 6)
        #self.assertEquals(N(s.encode('utf8')).lengthOfBytesUsingEncoding_(4), 5)
        
    def test_charactersatindex(self):
        text = N('Hello')
        self.assertEquals(text.characterAtIndex(0), ord('H'))
        self.assertEquals(text.characterAtIndex(1), ord('e'))
    '''

    def test_utf8string(self):
        text = N('Hello')
        self.assertEquals(text.UTF8String(), 'Hello')
