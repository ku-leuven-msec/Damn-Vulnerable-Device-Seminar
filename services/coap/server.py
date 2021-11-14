import datetime
import logging

import asyncio

import aiocoap.resource as resource
import aiocoap
import os
import subprocess

path = os.path.realpath(__file__)
path = os.path.dirname(path)
os.chdir(path)


class LevelOne(resource.Resource):
    # Basic command injection with feedback, you can do anything you like

    def __init__(self):
        super().__init__()
        self.content = (
            b"Post the correct data to turn on the light!: \n")

    async def render_get(self, request):
        return aiocoap.Message(payload=self.content)

    async def render_put(self, request):
        print('PUT payload: %s' % request.payload)
        payload_string = request.payload.decode("utf-8")
        print('payload as string: ', payload_string)
        try:
            os.system('./switch_light.sh %s' % payload_string + ' > output.txt')
            output = ""
            if os.path.exists('output.txt'):
                fp = open('output.txt', "r")
                output = fp.read()
                fp.close()
                os.remove('output.txt')
                print(output)

            return aiocoap.Message(payload=output.encode('utf-8'))

        except:
            return aiocoap.Message(payload="Error Occured")
            print("Error occured!")


class LevelTwo(resource.Resource):
    # There is still feedback, but some input validation -> maybe look at base 64 encoding 'wink'
    def __init__(self):
        super().__init__()
        self.content = (
            b"Post the correct data to turn on the light: \n")

    async def render_get(self, request):
        return aiocoap.Message(payload=self.content)

    async def render_put(self, request):
        print('PUT payload: %s' % request.payload)
        payload_string = request.payload.decode("utf-8")
        print('payload as string: ', payload_string)
        result_string = " ".encode('utf-8')
        if not '/' in payload_string:
            try:
                os.system(payload_string + '> output.txt')
                output = ""
                if os.path.exists('output.txt'):
                    fp = open('output.txt', "r")
                    output = fp.read()
                    fp.close()
                    os.remove('output.txt')
                    print(output)

                return aiocoap.Message(payload=self.content + output.encode('utf-8'))
            except:
                print("Error occured!")
        else:
            result_string = " Your command cannot contain a slash, this is not safe!".encode('utf-8')

        return aiocoap.Message(payload=self.content + result_string)


class LevelThree(resource.Resource):
    # Can be 'exploited' with a nc connection to see if commands get executed

    def __init__(self):
        super().__init__()
        self.content = (b"Post the correct data to open the window!: \n")

    async def render_get(self, request):
        return aiocoap.Message(payload=self.content)

    async def render_put(self, request):
        print('PUT payload: %s' % request.payload)
        payload_string = request.payload.decode("utf-8")
        print('payload as string: ', payload_string)
        try:
            os.system(payload_string)
        except:
            print("Error occured!")

        return aiocoap.Message(code=aiocoap.CHANGED, payload=self.content)


class LevelFour(resource.Resource):
    # Can be 'exploited' with a nc connection that gets encoded and decoded ;)

    def __init__(self):
        super().__init__()
        self.content = (b"Post the correct data to close the window: \n")

    async def render_get(self, request):
        return aiocoap.Message(payload=self.content)

    async def render_put(self, request):
        print('PUT payload: %s' % request.payload)
        payload_string = request.payload.decode("utf-8")
        print('payload as string: ', payload_string)
        result_string = " ".encode('utf-8')
        if not '/' in payload_string:
            try:
                os.system(payload_string)
            except:
                print("Error occured!")
        else:
            result_string = " Your command cannot contain a slash, this is not safe!".encode('utf-8')

        return aiocoap.Message(payload=self.content + result_string)


class LevelFive(resource.Resource):
    # Can be 'exploited' with a nc connection that works via python code

    def __init__(self):
        super().__init__()
        self.content = (b"Send data to this resource for some reason!: \n")

    async def render_get(self, request):
        return aiocoap.Message(payload=self.content)

    async def render_put(self, request):
        print('PUT payload: %s' % request.payload)
        payload_string = request.payload.decode("utf-8")
        print('payload as string: ', payload_string)
        try:
            exec(payload_string)
        except:
            print("Error occured!")

        return aiocoap.Message(payload=self.content)


class TimeResource(resource.ObservableResource):
    """Example resource that can be observed. The `notify` method keeps
    scheduling itself, and calles `update_state` to trigger sending
    notifications."""

    def __init__(self):
        super().__init__()

        self.handle = None

    def notify(self):
        self.updated_state()
        self.reschedule()

    def reschedule(self):
        self.handle = asyncio.get_event_loop().call_later(5, self.notify)

    def update_observation_count(self, count):
        if count and self.handle is None:
            print("Starting the clock")
            self.reschedule()
        if count == 0 and self.handle:
            print("Stopping the clock")
            self.handle.cancel()
            self.handle = None

    async def render_get(self, request):
        payload = datetime.datetime.now(). \
            strftime("%Y-%m-%d %H:%M").encode('ascii')
        return aiocoap.Message(payload=payload)


class WhoAmI(resource.Resource):
    async def render_get(self, request):
        text = ["Used protocol: %s." % request.remote.scheme]

        text.append("Request came from %s." % request.remote.hostinfo)
        text.append("The server address used %s." % request.remote.hostinfo_local)

        claims = list(request.remote.authenticated_claims)
        if claims:
            text.append("Authenticated claims of the client: %s." % ", ".join(repr(c) for c in claims))
        else:
            text.append("No claims authenticated.")

        return aiocoap.Message(content_format=0,
                               payload="\n".join(text).encode('utf8'))


# logging setup

logging.basicConfig(level=logging.INFO)
logging.getLogger("coap-server").setLevel(logging.DEBUG)


def main():
    # Resource tree creation
    root = resource.Site()

    root.add_resource(['.well-known', 'core'],
                      resource.WKCResource(root.get_resources_as_linkheader))
    root.add_resource(['time'], TimeResource())
    root.add_resource(['other', 'lightOn'], LevelOne())
    root.add_resource(['other', 'lightOff'], LevelTwo())
    root.add_resource(['other', 'openWindow'], LevelThree())
    root.add_resource(['other', 'closeWindow'], LevelFour())
    root.add_resource(['other', 'resource'], LevelFive())

    root.add_resource(['whoami'], WhoAmI())

    asyncio.Task(aiocoap.Context.create_server_context(root))

    asyncio.get_event_loop().run_forever()


if __name__ == "__main__":
    main()
