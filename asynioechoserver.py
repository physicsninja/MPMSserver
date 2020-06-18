import asyncio
import time

MPMS_buffer =[]
EXTERNAL_control_buffer = []

heartbeat = 'heartbeat'
heartbeat_reply = 'yeet:'
badcall = '400'

abort = 'ABORT'
report = 'reporting:'
send = 'send:'
receive = 'receive'
waiting = 'waiting'

#The command stucture TO the MPMS:
#		EXTERNAL:mget:12,COMMAND
#i.e. [From external:][4 letter command string:]
#		[GPIB address # if GPIB command][GPIB command string or MPMS command]
#		[\cr\lf are appended in the delphi EDC]

def now():
    return time.asctime(time.localtime()) +': '

def parse_data(data):
    ascii_data = data.decode('ascii')
    MPMS_key = 'MPMS:'
    external_key = 'EXTERNAL:'
   
    global MPMS_buffer
    global EXTERNAL_control_buffer

    #MPMS client calls to server
    if MPMS_key in ascii_data:

        if heartbeat in ascii_data: # is this just the MPMS checking in for new commands?
            if len(EXTERNAL_control_buffer) == 0: # there are no new commands
                print('Server response:' + heartbeat_reply+ '\r\n')
                return heartbeat_reply.encode('utf-8')

            elif len(EXTERNAL_control_buffer) == 1: #there is a command
                command = EXTERNAL_control_buffer.pop()
                print('Server response:' + command)
                return command.encode('utf-8')

            else: # something has gone wrong, the EC buffer should reject new commands if full
                  # unless it is abort
                latest_command = EXTERNAL_control_buffer.pop()
                if abort in latest_command:
                    EXTERNAL_control_buffer = [] #Clear the buffer, we succesfully aborted
                    print('Abort detected, Clearing buffer, Server response:' + command)
                    return abort.encode('utf-8')

                else:
                    raise ValueError('EXTERNAL_control_buffer corrupted, see log')


        elif report in ascii_data: # is the MPMS reporting something after a command?
            MPMS_buffer.append(ascii_data.replace(MPMS_key,'').replace(report,''))
            print('Server response:' + heartbeat_reply)
            return heartbeat_reply.encode('utf-8')

        else:
            print('Bad call, Server response:' + badcall)
            return badcall.encode('utf-8')
    
    # EXTERNAL client calls to server

    elif external_key in ascii_data:
        print(external_key)
        if send in ascii_data: # we try to send a command and:
            if len(EXTERNAL_control_buffer) == 0: # the MPMS is ready for it
                EXTERNAL_control_buffer.append(ascii_data.replace(external_key,'').replace(send,''))
                print('Server response:' + heartbeat_reply)
                return heartbeat_reply.encode('utf-8')

            else: #the MPMS is NOT ready for it
                print('Server response:' + waiting)
                return waiting.encode('utf-8')

        elif receive in ascii_data: # we try to see if our query was answered:
            if len(MPMS_buffer) == 1: # the MPMS has replied
                response = MPMS_buffer.pop()
                print('Server response:' + response)
                return response.encode('utf-8')
            elif len(MPMS_buffer) ==0: #the MPMS has NOT replied
                print('Server response:' + waiting)
                return waiting.encode('utf-8')
            else: 
                last = MPMS_buffer.pop()
                if abort in last: # successful abort override, clear buffer
                    MPMS_buffer = []
                    MPMS_buffer.append(abort)
                    print('Abort detected, Clearing buffer, Server response:' + heartbeat_reply)
                    return heartbeat_reply.encode('utf-8')
                else:
                    raise ValueError('MPMS_buffer corrupted, see log')

        else:
            print('Bad call, Server response:' + badcall)
            return badcall.encode('utf-8')

    else:
            print('Bad call, Server response:' + badcall)
            return badcall.encode('utf-8')  



async def handle_echo(reader, writer):
    data = await reader.read(100)
    message = data.decode()
    addr = writer.get_extra_info('peername')
    print(f"Received {message!r} from {addr!r}")
    response = parse_data(data)
    print(f"Send: {response!r}")
    writer.write(response)
    await writer.drain()
    print("Close the connection")
    writer.close()

async def main():
    server = await asyncio.start_server(
        handle_echo, '127.0.0.1', 8081)

    addr = server.sockets[0].getsockname()
    print(f'Serving on {addr}')

    async with server:
        await server.serve_forever()

asyncio.run(main())