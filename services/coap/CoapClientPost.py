import logging
import asyncio
from pickle import PUT
from aiocoap import *
logging.basicConfig(level=logging.INFO)
async def main():
    """Perform a single PUT request to localhost on the default port, URI
    "/other/block". The request is sent 2 seconds after initialization.
    The payload is bigger than 1kB, and thus sent as several blocks."""
    context = await Context.create_client_context()
    await asyncio.sleep(2)
    ip = input("Enter the ip of the raspberry that you want to POST information to \n")
    print("1: other/lightOn, 2: other/lightOff, 3: other/openWindow, 4: other/cloweWindow, 5: other/resource")
    level = input("Enter a number between 1 and 5 to show which resource you want to post to to \n")
    uri_string = ""
    if level == '1':
        uri_string = f"coap://{ip}/other/lightOn"
    elif level == '2':
        uri_string = f"coap://{ip}/other/lightOff"
    elif level == '3':
        uri_string = f"coap://{ip}/other/openWindow"
    elif level == '4':
        uri_string = f"coap://{ip}/other/closeWindow"
    elif level == '5':
        uri_string = f"coap://{ip}/other/resource"
    try:
        while True:
            payload_as_string = input("Enter a command to send to the device \n")
            payload = payload_as_string.encode()
            print('payload: %s' % payload)
            request = Message(code=PUT, payload=payload, uri=uri_string)
            response = await context.request(request).response
            print('Result: %s\n%r' % (response.code, response.payload))
    except KeyboardInterrupt:
        print('quited')
if __name__ == "__main__":
    asyncio.get_event_loop().run_until_complete(main())