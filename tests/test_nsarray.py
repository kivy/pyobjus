import pytest

from pyobjus import autoclass, objc_arr


@pytest.mark.parametrize(
    "input_array",
    [
        pytest.param([], id="empty array"),
        pytest.param([1, 2, 3], id="non empty array"),
    ]
)
def test_objc_arr_behaviour(input_array):
    NSArray = lambda: autoclass('NSArray')
    a1 = NSArray().arrayWithObjects_(*input_array + [None])
    a2 = objc_arr(*input_array)
    arr1 = [a1.objectAtIndex_(i).intValue() for i in range(a1.count())]
    arr2 = [a2.objectAtIndex_(i).intValue() for i in range(a2.count())]
    assert arr1 == arr2


@pytest.mark.parametrize(
    "array_without_nil,array_with_nil",
    [
        pytest.param([], [None], id="empty array"),
        pytest.param([1, 2, 3], [1, 2, 3, None], id="non empty array"),
    ]
)
def test_objc_arr_adds_nil(array_without_nil, array_with_nil):
    a1 = objc_arr(*array_without_nil)
    a2 = objc_arr(*array_with_nil)
    assert a1.count() == a2.count() == len(array_without_nil)
    arr1 = [a1.objectAtIndex_(i).intValue() for i in range(a1.count())]
    arr2 = [a2.objectAtIndex_(i).intValue() for i in range(a2.count())]
    assert arr1 == arr2


def test_enumerator_returns_none_past_the_end():
    enumerator = objc_arr(1, 2).objectEnumerator()
    assert enumerator.nextObject().intValue() == 1
    assert enumerator.nextObject().intValue() == 2
    assert enumerator.nextObject() is None
    assert enumerator.nextObject() is None


def test_nsarray_contains_its_object():
    NSString = autoclass("NSString")
    NSArray = autoclass("NSArray")
    text = NSString.alloc().initWithUTF8String_("some text for NSArray")
    array = NSArray.arrayWithObject_(text)
    assert array.objectAtIndex_(0).UTF8String() == "some text for NSArray"
    assert array.containsObject_(text)
