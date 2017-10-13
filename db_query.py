import datetime
import mysql.connector

cnx = mysql.connector.connect(user='root', database='profiles')
cursor = cnx.cursor()

query = ("SELECT f_name, l_name, ssn FROM PROFILE, WHERE f_name = %s AND l_name = %s")

f_name = # fetch f_name from file 
l_name = # fetch l_name from file

cursor.execute(query, (f_name, l_name))

for (f_name, l_name, ssn) in cursor:
    print("{}, {}, {}".format(
        l_name, f_name, ssn))

cursor.close()
cnx.close()