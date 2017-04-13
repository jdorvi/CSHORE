
from linecache import getline, clearcache, checkcache  
from datetime import datetime
import os

'''
with open('fort.63', 'r') as f:
    for i in range(0,5):
        print f.readline()
       
       
with open('fort.63', 'r') as f:
    end = len(f.readlines())       
'''
#---enter # of nodes in mesh
nnodes = 165290 

#----nodes of interest
node_list = [60643, 63290]

#---number of recordings 
tsteps = 289

#directories to loop through if desired (one only should work fine)
dirs = ['P:\\02\\LakeOntario\\Storm\\20080203','P:\\02\\LakeOntario\\Storm\\19701120',
        'P:\\02\\LakeOntario\\Storm\\19710210','P:\\02\\LakeOntario\\Storm\\19731103',
        'P:\\02\\LakeOntario\\Storm\\19710124']

clearcache()        
a = datetime.now()        
for i, d in enumerate(dirs):
    print d           
    os.chdir(d)   
    #----Read fort.63
    clearcache()
    
    for cur_node in node_list:
        name = str(cur_node)
        with open('fort'+str(i) +'_'+ name +'.txt', 'w') as f:
            for j in range(cur_node,(tsteps-1)*nnodes,nnodes+1):
                if j == cur_node:
                    f.write(getline('fort.63',j+3).rstrip() + '\n')
                else:
                    #print i, getline('fort.63',i+3).rstrip()
                    f.write(getline('fort.63',j+3).rstrip() +'\n')
    print os.getcwd(), 'maxele' 
    clearcache()
 '''   
    #----Read swan_HS.63
    for cur_node in node_list:
        with open('C:\Users\slawler\Desktop\\HS'+str(i) +'_'+ name +'.txt', 'w') as f:
            for i in range(cur_node,(tsteps-1)*nnodes,nnodes+1):
                if i == cur_node:
                    f.write(getline('swan_HS.63',j+3).rstrip() + '\n')
                else:
                    #print i, getline('swan_HS.63',j+3).rstrip()
                    f.write(getline('swan_HS.63',j+3).rstrip() +'\n')
                    
    print os.getcwd(), 'HS' 
    clearcache()
    
    #----Read swan_TP.63
    for cur_node in node_list:
        with open('C:\Users\slawler\Desktop\\TP'+str(i) +'_'+ name +'.txt', 'w') as f:
            for i in range(cur_node,(tsteps-1)*nnodes,nnodes+1):
                if i == cur_node:
                    f.write(getline('swan_TP.63',j+3).rstrip() + '\n')
                else:
                    #print i, getline('swan_TP.63',j+3).rstrip()
                    f.write(getline('swan_TP.63',j+3).rstrip() +'\n')
                    
    print os.getcwd(), 'TP'     
    clearcache()
'''        
b = datetime.now()
print b-a          
        
#---For 5 storms: 0:09:14.214000
