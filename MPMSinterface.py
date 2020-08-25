import socket
import time


class MPMS:
	def __init__(self, TCP_IP: str = '127.0.0.1', TCP_PORT: int = 8081, BUFFER_SIZE: int = 1024):
		self.ip = TCP_IP
		self.port = TCP_PORT
		self.buff = BUFFER_SIZE
		self.external_send = b'EXTERNAL:send:'
		self.external_receive = b'EXTERNAL:receive'


	def query_MPMS_server(self, command):
		"""
		Base query to the MPMS server. command must be a UTF-8 encoded string.

		"""
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.connect((self.ip,self.port))
		s.send(command)
		data = s.recv(self.buff)
		s.close()
		
		return data


	def set_GPIB(self, address: int, command_str):
		"""
		Method to write the UTF-8 encoded command_str to the GPIB instrument on the MPMS GPIB bus at the integer address
		"""
		to_send = self.external_send+b'gset:'+str(address).encode()+b':'+command_str
		deets = self.query_MPMS_server(to_send)
		if deets != b'yeet:':
			raise ValueError('Server Response is wrong, did not get yeet')
		deets = self.query_MPMS_server(self.external_receive)
		i = 0
		while deets == b'waiting' and i < 1000:
			deets = self.query_MPMS_server(self.external_receive)
			time.sleep(0.01)
			i = i + 1
		if i >= 1000:
			raise ValueError("Never received 'success'")
		return deets

	def get_GPIB(self, address: int, command_str):
		"""
		Method to query with the UTF-8 encoded command_str on the GPIB instrument on the MPMS GPIB bus at the integer address
		"""
		to_send = self.external_send+b'gget:'+str(address).encode()+b':'+command_str
		deets = self.query_MPMS_server(to_send)
		if deets != b'yeet:':
			raise ValueError('Server Response is wrong, did not get yeet')
		deets = self.query_MPMS_server(self.external_receive)
		i = 0
		while deets == b'waiting' and i < 1000:
			deets = self.query_MPMS_server(self.external_receive)
			time.sleep(0.01)
			i = i + 1
		if i >= 1000:
			raise ValueError("Never received reply")
		return deets

	@property
	def MPMStemperature(self):
		deets = self.query_MPMS_server(self.external_send+b'mget:stemp')
		if deets != b'yeet:':
			raise ValueError('Server Response is wrong, did not get yeet')
		deets = self.query_MPMS_server(self.external_receive)
		i = 0
		while deets == b'waiting' and i < 1000:
			deets = self.query_MPMS_server(self.external_receive)
			time.sleep(0.01)
			i = i + 1
		return float(deets)

	
	def set_MPMStemperature(self, t: float, rate: int = 5):
		"""
		Method to set the MPMS temperature (float) while specifying the nominal temperature ramp rate (integer)
		"""
		if rate > 10:
			rate = 10
		if t > 400:
			t = 400
		deets = self.query_MPMS_server(self.external_send+b'mset:stemp:'+str(t).encode()+b':'+str(rate).encode())
		if deets != b'yeet:':
			raise ValueError('Server Response is wrong, did not get yeet')
		deets = self.query_MPMS_server(self.external_receive)
		i = 0
		while deets == b'waiting' and i < 1000:
			deets = self.query_MPMS_server(self.external_receive)
			time.sleep(0.01)
			i = i + 1
		return deets


	@property
	def MPMSfield(self):
		deets = self.query_MPMS_server(self.external_send+b'mget:field')
		if deets != b'yeet:':
			raise ValueError('Server Response is wrong, did not get yeet')
		deets = self.query_MPMS_server(self.external_receive)
		i = 0
		while deets == b'waiting' and i < 1000:
			deets = self.query_MPMS_server(self.external_receive)
			time.sleep(0.01)
			i = i + 1
		return float(deets)

	
	def set_MPMSfield(self, field: float, options = b'11' ):
		"""
		Method to set the MPMS field
		The options correspond to the field approach modes, check the manual for meaning.
		THERE MUST BE TWO INTEGERS IN THE STRING
		"""
		if field > 70000:
			field  = 70000
		if field < -70000:
			field = -70000
		deets = self.query_MPMS_server(self.external_send+b'mset:field:'+str(field).encode()+b':'+options)
		if deets != b'yeet:':
			raise ValueError('Server Response is wrong, did not get yeet')
		deets = self.query_MPMS_server(self.external_receive)
		i = 0
		while deets == b'waiting' and i < 1000:
			deets = self.query_MPMS_server(self.external_receive)
			time.sleep(0.01)
			i = i + 1
		return deets
    
	def quit(self):
		"""
		Tell the MPMS to quit the procedure
		"""
		deets = self.query_MPMS_server(self.external_send+b'quit:')
		if deets != b'yeet:':
			raise ValueError('Server Response is wrong, did not get yeet')
