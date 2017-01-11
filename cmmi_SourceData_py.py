
# coding: utf-8

# In[187]:

path = "/Users/christine/Dropbox/Econometrica/CMMI_DatabaseProject/cmmi_src_text.json"
outfile = "/Users/christine/Dropbox/Econometrica/CMMI_DatabaseProject/cmmiOut.csv"
outfile2 = "/Users/christine/Dropbox/Econometrica/CMMI_DatabaseProject/cmmiOut_Models_withStates.csv"


# In[144]:

print path
print outfile


# In[145]:

import csv


# In[146]:

# Didn't end up using this, but it might be helpful 

class cmmiModel:
    """Object to hold model info"""
    
    def __init__(self, kw, num, desc, url, st, mn, stage, auth, dis_sum, cat):        
        self.keywords = kw
        self.participants = num
        self.description = desc
        self.url = url
        self.states = st
        self.modelname = mn
        self.stage = stage
        self.authority = auth
        self.displaysummary = dis_sum
        self.category = cat
        
    def getModelName(self):
        return self.modelname
    
    def getInfo(self):
        temp = []
        temp.append(self.modelname)
        temp.append(self.description)
        return temp
    


# In[147]:

def strSplit(mystring):
    return mystring.partition(":")[2]

strSplit("name: Christine")


# In[221]:

import json
import pandas

states = {
        'AK': 'Alaska',
        'AL': 'Alabama',
        'AR': 'Arkansas',
        'AS': 'American Samoa',
        'AZ': 'Arizona',
        'CA': 'California',
        'CO': 'Colorado',
        'CT': 'Connecticut',
        'DC': 'District of Columbia',
        'DE': 'Delaware',
        'FL': 'Florida',
        'GA': 'Georgia',
        'GU': 'Guam',
        'HI': 'Hawaii',
        'IA': 'Iowa',
        'ID': 'Idaho',
        'IL': 'Illinois',
        'IN': 'Indiana',
        'KS': 'Kansas',
        'KY': 'Kentucky',
        'LA': 'Louisiana',
        'MA': 'Massachusetts',
        'MD': 'Maryland',
        'ME': 'Maine',
        'MI': 'Michigan',
        'MN': 'Minnesota',
        'MO': 'Missouri',
        'MP': 'Northern Mariana Islands',
        'MS': 'Mississippi',
        'MT': 'Montana',
        'NA': 'National',
        'NC': 'North Carolina',
        'ND': 'North Dakota',
        'NE': 'Nebraska',
        'NH': 'New Hampshire',
        'NJ': 'New Jersey',
        'NM': 'New Mexico',
        'NV': 'Nevada',
        'NY': 'New York',
        'OH': 'Ohio',
        'OK': 'Oklahoma',
        'OR': 'Oregon',
        'PA': 'Pennsylvania',
        'PR': 'Puerto Rico',
        'RI': 'Rhode Island',
        'SC': 'South Carolina',
        'SD': 'South Dakota',
        'TN': 'Tennessee',
        'TX': 'Texas',
        'UT': 'Utah',
        'VA': 'Virginia',
        'VI': 'Virgin Islands',
        'VT': 'Vermont',
        'WA': 'Washington',
        'WI': 'Wisconsin',
        'WV': 'West Virginia',
        'WY': 'Wyoming'
}


# In[252]:

class BlankDict(dict):
        def __missing__(self, key):
            return u'Missing'
        
def checkStates(modelStates, stateDict):
    binaryOut = []

    for i in stateDict:
        binaryOut.append(0)
    
    # If an entry contains general info and doesn't refer to an actual model, there won't be any states listed
    if 'Missing' in modelStates:
        return binaryOut
    else:
        for state in modelStates:
            # print state
            dummy = state.strip()
            # print state, dummy 
            temp = sorted(stateDict.keys()).index(dummy)
            # print temp
            binaryOut[temp] = 1
        return binaryOut
    
                
with open(path) as json_data:
    cmmiData = json.load(json_data, object_hook=BlankDict)
    len(data) # should = 79

with open(outfile, "wb+") as csv_file:
    csv_writer = csv.writer(csv_file)   
    csv_writer.writerow(["Model_Name", "Category", "States", "Keywords", "Num_Participants", "Description", "url", 
                       "Stage", "Authority", "Display_Summary"])
    for i in cmmiData:    
        csv_writer.writerow([i[u'model_name'].encode('utf8'),
                            i[u'category'].encode('utf8'),
                            i[u'states'].encode('utf8'),
                            i[u'keywords'].encode('utf8'),
                            i[u'number_of_participants'].encode('utf8'),
                            i[u'description'].encode('utf8'),
                            i[u'url'].encode('utf8'),    
                            i[u'stage'].encode('utf8'),
                            i[u'authority'].encode('utf8'),
                            i[u'display_model_summary'].encode('utf8')])
        
with open(outfile2, "wb+") as csv_file2:
    csv_writer2 = csv.writer(csv_file2)
    stateAbbr = sorted(states.keys())    
       
    header = []
    header.append("Model_Name")
    header.append("Category")
    header.append("Stage")
    header.append("List of States")
    header.append("Number of States")
    # header.append("Checksum")
    # header.append("Num == check")
    
    for state in stateAbbr:
        header.append(state)

    csv_writer2.writerow(header)
    
    for j in cmmiData:
        getStates = str(j[u'states']).split(",")
           
        binaryStates = checkStates(getStates, states)
        
        row = []
        row.append(j[u'model_name'].encode('utf8'))
        row.append(j[u'category'].encode('utf8'))
        row.append(j[u'stage'].encode('utf8'))
        row.append(j[u'states'])
        # row.append(len(getStates))
        row.append(sum(binaryStates))
        # row.append(len(getStates) == sum(binaryStates))
        
        '''if(len(getStates)!= sum(binaryStates)):
            counter = 0
            print sorted(getStates)
            for i in sorted(getStates):
                print i, binaryStates[counter]
                counter += 1'''
    
        for s in binaryStates:
            row.append(s)
        
        csv_writer2.writerow(row)
        #TODO: put in error checking re: # of states in the JSON don't match the # of 1s that get put (checksum)
        #modelStates.append(j[u'states'].encode('utf8'))
    
    


# In[250]:

len(states)


# In[ ]:



