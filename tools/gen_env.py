import os

#set params
account = r'sims2016'
password = r'Sims_2016'
ip = r'WANGBIN-8QWNF62\THIRD'
path = r'..\tables'


#
account = ' -U' + account
password = ' -P' + password
ip = ' -S' + ip

fpaths = open('.\path.txt', 'w')

for root, dirs, files in os.walk(path):
	fpaths.write('cysql32 -T' + account + password + ip + ' ' + root + '\*.sql\n')

fpaths.close()

#
