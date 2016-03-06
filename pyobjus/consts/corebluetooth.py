from pyobjus.consts import ObjcConstType, Const


class CBAdvertisementDataKeys(ObjcConstType):
    '''
    Key values for CoreBluetooth advertisement features.
    '''

    frameworks = ['CoreBluetooth']

    LocalName = Const('CBAdvertisementDataLocalNameKey', 'kCBAdvDataLocalName')
    ServiceUUIDs = Const('CBAdvertisementDataServiceUUIDsKey',
                         'kCBAdvDataServiceUUIDs')
    ManufacturerData = Const('CBAdvertisementDataManufacturerDataKey',
                             'kCBAdvDataManufacturerData')
