"""Build the editable native MVP interaction design with the installed FigCraft CLI.

Run this from the repository root. It writes a command script and node manifest
beside this file; the README documents the CLI invocation that makes the canvas.
All content is fictional review data, not imported personal captures.
"""
from pathlib import Path
import json

# The installed CLI predates symbolic step references. Track numeric node IDs,
# including descendants cloned by instances, so every parent and prototype is exact.
OUT = Path(__file__).resolve().parent
commands = []
next_id = 2
children = {}
frames = {}
hotspots = []
C = {'canvas':'#E8E8E8','paper':'#F5F5F5','surface':'#FBFBFB',
     'ink':'#242424','muted':'#666666','line':'#D6D6D6','soft':'#E9E9E9',
     'inverse':'#F9F9F9','key':'#FCFCFC','keybed':'#DADADA'}


def cmd(command, **params):
    """Append an engine command, leaving the generated JSON as reproducible data."""
    commands.append({'command':command, 'params':params})


def node(kind, parent=1, x=0, y=0, w=100, h=40, name='', **props):
    """Create an editable layer and remember its children for instance allocation."""
    global next_id
    ident = next_id
    next_id += 1
    cmd('node.create', type=kind, parent=parent, x=x, y=y, width=w, height=h,
        name=name, props=props)
    children[ident] = []
    if parent in children:
        children[parent].append(ident)
    return ident


def rect(parent,x,y,w,h,fill='surface',radius=0,name='',stroke=None):
    """Draw a flat surface; hierarchy comes from spacing and thin rules."""
    props={'fill':C.get(fill,fill),'cornerRadius':radius}
    if stroke:
        props.update(stroke=C.get(stroke,stroke),strokeWeight=1)
    return node('rectangle',parent,x,y,w,h,name,**props)


def text(parent,x,y,value,size=16,w=345,h=None,color='ink',weight=400,name=''):
    """Use one neutral type family and explicit wrapping bounds throughout."""
    ident=node('text',parent,x,y,w,h or int(size*1.6),name or value[:48],
               fontFamily='Avenir Next',fontSize=size,fontWeight=weight,
               lineHeight=round(size*1.5),fill=C[color],textAutoResize='none')
    cmd('node.set',id=ident,characters=value)
    return ident


def line(parent,x,y,w):
    """A one-point divider replaces decorative cards and shadows."""
    return rect(parent,x,y,w,1,'line')


def count_tree(ident):
    """Count every cloned layer, which the CLI allocates contiguous IDs for."""
    return 1+sum(count_tree(child) for child in children[ident])


def instance(component,parent,x,y,w=None):
    """Place a genuine linked component instance, not a flattened copy."""
    global next_id
    ident=next_id
    next_id+=count_tree(component)
    cmd('instance.create',component=component,parent=parent,x=x,y=y)
    return ident


def button(parent,x,y,label,w=345,quiet=False):
    """Place a shared button and override its label on the copied text layer."""
    ident=instance(secondary if quiet else ({345:primary,103:small_primary,145:mac_primary}[w]),parent,x,y)
    cmd('node.set',id=ident+1,characters=label)
    return ident


def frame(name,x,y,w=393,h=852):
    """Register a native-size screen for exports and prototype destinations."""
    ident=node('frame',1,x,y,w,h,name,fill=C['paper'],clip=True)
    frames[name]=ident
    return ident


def status(parent,w=393):
    """Represent the phone safe area without implying a specific device model."""
    text(parent,24,16,'9:41',14,w=60,weight=600)
    text(parent,w-112,16,'5G   100%',12,w=94)
    rect(parent,w/2-58,8,116,25,'ink',14)


def tabs(parent,active,y=764,w=393):
    """Capture, Find and Chat are one-step mode changes with preserved drafts."""
    line(parent,0,y,w)
    for i,label in enumerate(['Capture','Find','Chat']):
        x=12+i*(w-24)/3
        if label==active:
            rect(parent,x,y+9,(w-24)/3-4,44,'soft',4)
        ident=text(parent,x+16,y+18,label,14,w=(w-24)/3-26,weight=600 if label==active else 400)
        hotspots.append((ident,'Phone / '+label))
    rect(parent,w/2-64,832,128,4,'ink',2)


def phone(name,x,active,subtitle):
    """Add shared safe areas, mode header, sync entry and bottom navigation."""
    f=frame(name,x,0)
    status(f)
    text(f,24,74,active,25,weight=600)
    sync=text(f,278,83,'Synced',12,w=88,color='muted')
    hotspots.append((sync,'Phone / Sync'))
    text(f,24,118,subtitle,13,color='muted')
    tabs(f,active)
    return f


# The component shelf is part of the same editable file and provides real Assets.
cmd('file.rename',name='Headless second brain — native MVP')
cmd('page.rename',id=1,name='01 · Keyboard first')
cmd('page.setBackground',color=C['canvas'])
shelf=frame('Components / Greyscale controls',2370,980,520,840)
text(shelf,24,25,'CONTROLS',12,color='muted',weight=600)
text(shelf,24,60,'One typeface. No brand layer.',23,w=472,weight=500)
text(shelf,24,104,'Editable components used in the screens below.',14,w=472,color='muted')
primary=node('component',shelf,24,160,345,48,'Button / Primary',fill=C['ink'],cornerRadius=4)
text(primary,12,12,'Save',15,w=321,h=26,color='inverse',weight=600)
secondary=node('component',shelf,24,232,345,48,'Button / Secondary',fill=C['paper'],stroke=C['line'],strokeWeight=1,cornerRadius=4)
text(secondary,12,12,'Edit reminder',15,w=321,h=26,weight=500)
small_primary=node('component',shelf,390,160,103,48,'Button / Compact',fill=C['ink'],cornerRadius=4)
text(small_primary,12,12,'Save',15,w=79,h=26,color='inverse',weight=600)
mac_primary=node('component',shelf,24,780,145,48,'Button / Mac',fill=C['ink'],cornerRadius=4)
text(mac_primary,12,12,'Save',15,w=121,h=26,color='inverse',weight=600)
key=node('component',shelf,24,320,32,40,'Keyboard / Key',fill=C['key'],cornerRadius=4)
text(key,5,6,'A',17,w=24,h=29)
text(shelf,24,390,'Type',12,color='muted')
for y,size,label in [(426,25,'Screen title / 25'),(478,17,'Body / 17'),(520,14,'Control / 14'),(556,12,'Status / 12')]:
    text(shelf,24,y,label,size,w=460)
for i,(name,col) in enumerate(C.items()):
    if i>7: break
    rect(shelf,24+i*58,640,38,38,col,0)
    text(shelf,24+i*58,686,name,9,w=55,color='muted')
text(shelf,24,744,'Implementation: 44 pt targets · 1 pt dividers',12,w=472,color='muted')

# Phone companion screens preserve full document editing outside the keyboard.
f=phone('Phone / Capture',0,'Capture','Write anything. No title or filing required.')
text(f,24,173,'An idea for the weekend',20,weight=500)
text(f,24,218,'Build a small shelf for the plants.\nKeep the design simple enough to\nfinish in an afternoon.\n\nhttps://example.com/shelf',17,h=230)
line(f,24,505,345)
text(f,24,526,'B     I     • List     ☐ Checklist     +',15)
save=button(f,24,600,'Save')
hotspots.append((save,'Phone / Reminder'))
text(f,24,667,'Stored on this device first.',12,color='muted')

f=phone('Phone / Find',430,'Find','Search your captures and remembered conversation.')
rect(f,24,165,345,48,'surface',4,stroke='line')
text(f,38,177,'the idea about the plants',15,w=319)
text(f,24,235,'Everything',13,weight=600)
open_tasks=text(f,140,235,'Open tasks',13,color='muted',w=160)
hotspots.append((open_tasks,'Phone / Open tasks'))
for y,title,excerpt,meta in [(292,'An idea for the weekend','Build a small shelf for the plants.','Today · Capture'),(430,'A thought about small projects','Choose something I can finish in one day.','18 Oct · Chat')]:
    text(f,24,y,meta,11,color='muted')
    hit=text(f,24,y+30,title,18,weight=500)
    text(f,24,y+67,excerpt,14,color='muted')
    line(f,24,y+110,345)
    hotspots.append((hit,'Phone / Original'))
text(f,24,690,'Original words stay available.',12,color='muted')

f=phone('Phone / Original',860,'Find','Original capture · Today, 09:12')
text(f,24,175,'An idea for the weekend',23,weight=500)
text(f,24,225,'Build a small shelf for the plants.\nKeep the design simple enough to\nfinish in an afternoon.',17,h=150)
text(f,24,394,'https://example.com/shelf',15,color='muted')
line(f,24,465,345)
text(f,24,490,'Edit original         Copy',14)
chat=button(f,24,596,'Continue in chat')
hotspots.append((chat,'Phone / Chat'))
text(f,24,666,'Remove     ·     Stop resurfacing',12,color='muted')

f=phone('Phone / Chat',1290,'Chat','One continuing conversation.')
text(f,24,162,'Remembered',12,color='muted')
temp=text(f,259,162,'Temporary',12,w=110)
hotspots.append((temp,'Phone / Temporary'))
rect(f,60,206,309,86,'soft',4)
text(f,76,221,'What was my idea for the weekend?',15,w=276,h=58)
text(f,24,324,'You saved an idea to build a small\nshelf for the plants, keeping it small\nenough to finish in an afternoon.',16,h=102)
source=text(f,24,440,'↗ An idea for the weekend',12,color='muted')
hotspots.append((source,'Phone / Original'))
line(f,24,490,345)
text(f,24,514,'REMINDER · TODAY, 10:00',10,color='muted',weight=600)
text(f,24,542,'Buy a gift for mum’s birthday',16,weight=500)
edit=text(f,24,581,'Edit reminder',13)
hotspots.append((edit,'Phone / Reminder'))
text(f,190,581,'Remove',13,w=120,color='muted')
rect(f,24,666,345,60,'surface',4,stroke='line')
text(f,38,682,'Move the gift reminder to tomorrow…',13,w=289,color='muted')

f=phone('Phone / Reminder',1720,'Capture','Saved. You can keep writing.')
text(f,24,177,'Buy a gift for mum’s birthday',20,weight=500)
text(f,24,222,'A sketchbook and something for\nher garden.',16,h=75)
line(f,24,344,345)
text(f,24,372,'Set a date and reminder?',18,weight=500)
text(f,24,410,'For checklists, this date applies to the whole list.',12,color='muted')
text(f,24,458,'DATE',10,color='muted')
rect(f,24,482,211,48,'surface',4,stroke='line')
text(f,38,494,'21 October 2026',15,w=182)
text(f,253,458,'TIME',10,color='muted',w=110)
rect(f,253,482,116,48,'surface',4,stroke='line')
text(f,267,494,'09:00',15,w=88)
text(f,24,550,'Asia/Kolkata · keeps this time zone',12,color='muted')
set_due=button(f,24,602,'Set date & reminder')
hotspots.append((set_due,'Phone / Chat'))
notnow=text(f,24,674,'Not now',14,color='muted')
hotspots.append((notnow,'Phone / Capture'))

f=phone('Phone / Sync',2150,'Capture','Your devices. One private vault.')
text(f,24,180,'Devices',18,weight=600)
for y,title,detail in [(233,'This iPhone','Up to date · just now'),(325,'Your Mac','Up to date · 2 minutes ago')]:
    text(f,24,y,title,17)
    text(f,24,y+34,detail,12,color='muted')
    line(f,24,y+76,345)
text(f,24,452,'Your notes stay usable offline.\nSynced content is encrypted before\nit leaves a device.',16,h=110)
text(f,24,574,'Cloud AI: Off',15)
text(f,24,608,'Turning it on is a separate choice.',12,color='muted')
button(f,24,674,'Connect another device',quiet=True)

# Two secondary phone states make checklist and Temporary behavior concrete.
f=frame('Phone / Open tasks',0,940)
status(f);text(f,24,74,'Open tasks',25,weight=600);text(f,24,118,'Unfinished items from your captures.',13,color='muted');tabs(f,'Find')
text(f,24,179,'Weekend shelf',19,weight=500)
for y,label,done in [(236,'Measure the corner',True),(292,'Buy wood and brackets',False),(348,'Build and fit the shelf',False)]:
    rect(f,24,y,22,22,'ink' if done else 'paper',3,stroke='line')
    if done:text(f,28,y-1,'✓',15,w=24,color='inverse')
    text(f,62,y-1,label,16,w=300,color='muted' if done else 'ink')
text(f,24,414,'Due 21 Oct, 09:00 · Asia/Kolkata',12,color='muted')
line(f,24,466,345)
text(f,24,493,'Buy a gift for mum’s birthday',18,weight=500)
text(f,24,530,'Overdue · 20 Oct, 10:00',12,color='muted')
text(f,24,568,'Edit reminder       Open original',14)
text(f,24,698,'Completed lists cancel pending reminders.',12,color='muted')

f=frame('Phone / Temporary',430,940)
status(f);text(f,24,74,'Chat',25,weight=600);text(f,24,118,'Temporary segment',13,color='muted');tabs(f,'Chat')
rect(f,24,168,345,88,'soft',4)
text(f,38,181,'Temporary',16,weight=500)
text(f,38,214,'Can use your vault. Saves no new conversation.',12,w=317,color='muted')
text(f,24,299,'Ask something without retaining\nthis part of the conversation.',18,h=76)
button(f,24,584,'Return to remembered chat',quiet=True)
rect(f,24,666,345,60,'surface',4,stroke='line');text(f,38,683,'Message…',14,w=290,color='muted')

# Keyboard screens include a fictional host app to expose the private-input boundary.
def keys(parent,y):
    """Place linked key instances; the extension owns this typing plane."""
    rect(parent,0,y,393,218,'keybed')
    for row,letters in enumerate(['QWERTYUIOP','ASDFGHJKL','ZXCVBNM']):
        offset=[6,25,62][row]
        for col,letter in enumerate(letters):
            ident=instance(key,parent,offset+col*38,y+8+row*48)
            cmd('node.set',id=ident+1,characters=letter)
    # Shift and delete complete the basic alphabetic typing controls.
    rect(parent,6,y+104,48,40,'soft',4);text(parent,16,y+112,'↑',19,w=30)
    rect(parent,334,y+104,52,40,'soft',4);text(parent,343,y+115,'Del',11,w=40)
    rect(parent,6,y+152,68,42,'soft',4);text(parent,17,y+162,'123',14,w=53)
    rect(parent,82,y+152,228,42,'key',4);text(parent,160,y+162,'space',13,w=90)
    rect(parent,318,y+152,68,42,'soft',4);text(parent,328,y+162,'return',12,w=58)
    text(parent,18,y+198,'◉',14,w=30)
    text(parent,85,y+199,'Private pad · host draft stays unchanged',10,w=275,color='muted')


def keyboard(name,x,mode,pad_top=356):
    """A compact three-mode extension leaves room for actual keyboard keys."""
    f=frame(name,x,1880)
    status(f)
    text(f,24,78,'EXAMPLE HOST APP',11,w=260,color='muted')
    text(f,24,123,'Your conversation stays here',17,w=345,weight=500)
    rect(f,24,190,285,72,'soft',12)
    text(f,40,206,'Do you have the link to that\nweekend project?',15,w=252,h=54)
    rect(f,24,294,345,48,'surface',20,stroke='line')
    text(f,40,307,'Let me find it…',14,color='muted')
    # The note grows upward inside a taller requested extension. It never draws
    # a separate window over the host; the letter keys retain their positions.
    rect(f,0,pad_top,393,852-pad_top,'paper')
    line(f,0,pad_top,393)
    for i,label in enumerate(['Capture','Find','Chat']):
        if label==mode:rect(f,i*96+4,pad_top+8,90,36,'soft',4)
        ident=text(f,i*96+17,pad_top+17,label,12,w=82,weight=600 if label==mode else 400)
        hotspots.append((ident,'Keyboard / '+label))
    resize=text(f,302,pad_top+17,'Size ↕',12,w=82)
    hotspots.append((resize,{'Sizing / Expanded':'Sizing / Minimised','Sizing / Minimised':'Sizing / Default'}.get(name,'Sizing / Expanded')))
    keys(f,612)
    rect(f,132,841,129,4,'ink',2)
    return f

f=keyboard('Keyboard / Capture',0,'Capture')
rect(f,16,414,361,130,'surface',4,stroke='line')
text(f,28,426,'Write a note here…',17,w=337,color='muted')
text(f,28,516,'B   I   • List   ☐ Checklist',12,w=337,color='muted')
b=button(f,272,550,'Save',103);hotspots.append((b,'Keyboard / Saved'))
text(f,18,562,'Notepad inside your keyboard',11,w=237,color='muted')
f=keyboard('Keyboard / Find',430,'Find')
rect(f,16,414,361,40,'surface',4,stroke='line');text(f,28,424,'the weekend shelf link',14,w=338)
hit=text(f,18,475,'An idea for the weekend',16,w=357,weight=500)
text(f,18,514,'Today · Capture',11,w=230,color='muted')
text(f,304,559,'Insert',13,w=75)
hotspots.append((hit,'Keyboard / Original'))
f=keyboard('Keyboard / Chat',860,'Chat')
text(f,18,423,'Reminder · Buy a gift for mum',13,w=357,weight=500)
text(f,18,458,'Today, 10:00 · Asia/Kolkata',11,w=357,color='muted')
rect(f,16,551,361,42,'surface',4,stroke='line')
text(f,28,562,'Move this to tomorrow at 10…',13,w=295,color='muted');text(f,338,559,'↑',18,w=28)
f=keyboard('Keyboard / Saved',1290,'Capture')
text(f,18,423,'Saved on this device',15,w=357,weight=500)
text(f,18,463,'Make this a reminder?',12,w=357,color='muted')
text(f,18,553,'21 Oct      09:00',14,w=225)
b=button(f,272,550,'Set',103);hotspots.append((b,'Keyboard / Chat'))

# Opening an original stays inside the keyboard workspace. Insertion is a
# separate explicit effect, and the displayed host draft changes only afterward.
f=keyboard('Keyboard / Original',1720,'Find')
back=text(f,18,417,'‹ Results',11,w=210,color='muted')
hotspots.append((back,'Keyboard / Find'))
text(f,18,451,'An idea for the weekend',15,w=357,weight=500)
text(f,18,487,'Build a small shelf for the plants. Keep it…',12,w=357,h=28)
text(f,18,578,'Scroll original',10,w=200,color='muted')
b=button(f,272,554,'Insert',103);hotspots.append((b,'Keyboard / Inserted'))
f=keyboard('Keyboard / Inserted',2150,'Find')
text(f,18,423,'Inserted into your host draft',15,w=357,weight=500)
text(f,18,468,'Your original stays in the vault.',12,w=357,color='muted')
text(f,18,560,'Switch keyboard to continue your reply.',12,w=357,color='muted')
# Replace the fictional host draft only in this explicit-insertion state.
# The host label is presentation context, not the app's name.
for entry in reversed(commands):
    if entry['command']=='node.set' and entry['params'].get('characters')=='Let me find it…':
        entry['params']['characters']='Build a small shelf for the plants.'
        break

# Three explicit height states keep the same text and routing. The collapsed
# pad retains a visible current line; it never silently targets the host app.
size_draft='Build a small shelf for the plants.\nKeep it simple enough to finish in\nan afternoon. Measure the corner,\nthen buy wood and brackets.\n\nMaybe add a second shelf later.'
for state,x,top,editor_y,editor_h in [('Minimised',0,524,574,30),('Default',430,356,414,130),('Expanded',860,164,222,322)]:
    f=keyboard('Sizing / '+state,x,'Capture',pad_top=top)
    editor=node('frame',f,16,editor_y,361,editor_h,'Resizable note viewport',
                fill=C['surface'],cornerRadius=4,stroke=C['line'],strokeWeight=1,clip=True)
    # The displayed tail follows the preserved caret. A clipped text viewport
    # prevents long notes from painting over formatting or Save controls.
    body_h=editor_h if state=='Minimised' else editor_h-34
    body=node('frame',editor,0,0,361,body_h,'Scrollable note body',fill=C['surface'],clip=True)
    displayed={'Minimised':'Maybe add a second shelf later.│',
               'Default':'then buy wood and brackets.\n\nMaybe add a second shelf later.│',
               'Expanded':size_draft+'│'}[state]
    text(body,12,7,displayed,14,w=337,h=max(20,editor_h-12))
    if state!='Minimised':
        text(editor,12,editor_h-29,'B   I   • List   ☐ Checklist',12,w=337,color='muted')
        button(f,272,550,'Save',103)
        text(f,18,563,'Note input · '+state.lower(),11,w=237,color='muted')
# Mac is a dismissible native panel over the current app, not a dashboard.
def mac(name,x,mode):
    """Keep one small panel with modes, status, and an Escape exit cue."""
    f=frame(name,x,2830,680,580)
    text(f,24,19,'Second brain',12,color='muted')
    text(f,548,19,'Esc to close',11,w=110,color='muted')
    line(f,0,54,680)
    for i,label in enumerate(['Capture','Find','Chat']):
        if label==mode:rect(f,20+i*112,67,103,40,'soft',4)
        ident=text(f,32+i*112,77,label,14,w=90,weight=600 if label==mode else 400)
        hotspots.append((ident,'Mac / '+label))
    text(f,538,79,'Synced',11,w=120,color='muted')
    return f
f=mac('Mac / Capture',0,'Capture')
text(f,28,146,'A thought to keep…',23,w=624,color='muted')
text(f,28,199,'Write a line, paste a link, or keep going.',15,w=624,color='muted')
line(f,24,444,632);text(f,28,465,'B    I    • List    ☐ Checklist    +',14,w=450)
b=button(f,511,458,'Save',145);hotspots.append((b,'Mac / Chat'))
text(f,28,532,'⌘ Enter to save',12,w=350,color='muted')
f=mac('Mac / Find',740,'Find')
rect(f,24,132,632,48,'surface',4,stroke='line');text(f,38,144,'the plants project',17,w=594)
text(f,28,205,'Everything       Open tasks',12,w=600,color='muted')
text(f,28,258,'An idea for the weekend',20,w=600,weight=500)
text(f,28,301,'Build a small shelf for the plants.',16,w=600)
text(f,28,343,'Today · Original capture',12,w=600,color='muted');line(f,24,390,632)
text(f,28,429,'Enter to open     ·     Copy     ·     Insert',13,w=600,color='muted')
f=mac('Mac / Chat',1480,'Chat')
text(f,28,141,'REMINDER · TODAY, 10:00',11,w=600,color='muted')
text(f,28,174,'Buy a gift for mum’s birthday',21,w=600,weight=500)
text(f,28,221,'Edit reminder       Remove',13,w=600);line(f,24,264,632)
text(f,28,296,'You',11,w=600,color='muted')
text(f,28,323,'Move this to tomorrow at 10.',17,w=600)
text(f,28,370,'Proposed result after a successful schedule edit:',11,w=600,color='muted')
text(f,28,395,'21 October, 10:00 · Asia/Kolkata',16,w=600)
rect(f,24,474,632,62,'surface',4,stroke='line');text(f,38,494,'Message…',14,w=540,color='muted')

# Prototype links navigate known states; they do not pretend to perform real saves.
for source,target in hotspots:
    if target in frames:
        cmd('proto.interaction.add',id=source,dest=frames[target])
cmd('proto.flow.add',start=frames['Keyboard / Capture'],name='START HERE · Keyboard notepad')
cmd('proto.flow.add',start=frames['Phone / Capture'],name='Secondary · Companion app')
cmd('proto.flow.add',start=frames['Mac / Capture'],name='Mac hotkey panel')
cmd('proto.flow.add',start=frames['Sizing / Default'],name='Same draft · three pad sizes')
# Separate primary and supporting surfaces into named pages. Opening the file
# starts with keyboard flows; companion screens no longer lead the presentation.
for page_name,prefix in [('02 · Pad sizes','Sizing /'),('03 · Mac hotkey','Mac /'),('04 · Companion and setup','Phone /'),('05 · Components','Components /')]:
    page_id=next_id
    next_id+=1
    cmd('page.add',name=page_name)
    matching=[(name,ident) for name,ident in frames.items() if name.startswith(prefix)]
    for i,(name,ident) in enumerate(matching):
        cmd('node.reparent',ids=[ident],parent=page_id)
        columns=3 if prefix=='Mac /' else 4
        width_step=740 if prefix=='Mac /' else (560 if prefix=='Components /' else 430)
        cmd('node.set',id=ident,x=(i%columns)*width_step,y=(i//columns)*940)
for name,ident in frames.items():
    if name.startswith('Keyboard /'):
        cmd('node.set',id=ident,y=0)
cmd('page.select',id=1)
cmd('select.set',ids=[frames['Keyboard / Capture']])
cmd('view.zoomSelection')
cmd('component.list')
cmd('inspect.code',id=primary,language='swiftui')

# Keep the command stream and node manifest next to the native file for handoff.
OUT.mkdir(exist_ok=True)
(OUT/'native-mvp.commands.json').write_text(json.dumps(commands,indent=2,ensure_ascii=False)+'\n')
(OUT/'native-mvp.manifest.json').write_text(json.dumps({'frames':frames,'components':{'primary':primary,'secondary':secondary,'key':key},'expectedNodes':next_id-1,'commandCount':len(commands)},indent=2)+'\n')
print(f'{len(commands)} commands; {len(frames)} top-level frames; {next_id-1} expected nodes')
