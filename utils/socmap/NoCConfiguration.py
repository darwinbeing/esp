#!/usr/bin/python3
from tkinter import *
import Pmw
import xml.etree.ElementTree

import functools
from soc import *

def isInt(s):
  try: 
    int(s)
    return True
  except ValueError:
    return False


class Characterization():
  ip = ""
  vf_points = []

class VFPoint():
  voltage = 0
  frequency = 0
  energy = 0

class Tile():

  def update_tile(self, soc):
    selection = self.ip_type.get()
    self.label.config(text=selection)
    if soc.IPs.PROCESSORS.count(selection):
       self.label.config(bg='deep pink')
    elif soc.IPs.MISC.count(selection):
       self.label.config(bg='gray')
    elif soc.IPs.MEM.count(selection):
       self.label.config(bg='green')
    elif soc.IPs.ACCELERATORS.count(selection):
       self.label.config(bg='orange')
    else:
       self.label.config(bg='white')

    try:
      if soc.IPs.PROCESSORS.count(selection) or soc.IPs.ACCELERATORS.count(selection):
         self.clk_reg_selection.config(state=NORMAL)
         if self.clk_region.get() != 0:
           self.pll_selection.config(state=NORMAL)
         else:
           self.pll_selection.config(state=DISABLED)
           if self.has_pll.get() == 1 :
             self.has_pll.set(0)
         if self.has_pll.get() == 1:
           self.clkbuf_selection.config(state=NORMAL)
         else:
           self.clkbuf_selection.config(state=DISABLED)
           if self.has_clkbuf.get() == 1 :
             self.has_clkbuf.set(0)
      else:
         self.clk_reg_selection.config(state=DISABLED)
         self.pll_selection.config(state=DISABLED)
         self.clkbuf_selection.config(state=DISABLED)
         if self.clk_region.get() > 0 :
           self.clk_region.set(0)
         if self.has_pll.get() == 1 :
           self.has_pll.set(0)
         if self.has_clkbuf.get() == 1 :
           self.has_clkbuf.set(0)
    except:
      pass

    self.load_characterization(soc, soc.noc.vf_points)

  def get_clk_region(self):
    return self.clk_region.get()

  def center(self, toplevel):
    toplevel.update_idletasks()
    w = toplevel.winfo_screenwidth()
    h = toplevel.winfo_screenheight()
    size = tuple(int(_) for _ in toplevel.geometry().split('+')[0].split('x'))
    x = w/2 - size[0]/2 + 100
    y = h/2 - size[1]/2
    toplevel.geometry("%dx%d+%d+%d" % (size + (x, y)))

  def create_characterization(self, soc, num_points):
    self.energy_values = Characterization()
    self.energy_values.ip = self.ip_type.get()
    self.energy_values.vf_points = [VFPoint() for x in range(num_points)]

  def load_characterization(self, soc, num_points):
    selection = self.ip_type.get()
    if self.energy_values == None or len(self.energy_values.vf_points) == 0:
       self.create_characterization(soc, num_points)
    if self.energy_values.ip != selection and soc.IPs.ACCELERATORS.count(selection):
      e = xml.etree.ElementTree.parse('../../utils/socmap/power.xml').getroot()
      self.energy_values.ip = selection
      for atype in e.findall('accelerator'):
        if atype.get('name') == self.ip_type.get():
          xml_vf_points = atype.findall('vf_point')
          end_point = num_points
          if len(xml_vf_points) < end_point:
            end_point = len(xml_vf_points)
          for x in range(end_point):
            self.energy_values.vf_points[x].voltage = float(xml_vf_points[x].get('voltage'))
            self.energy_values.vf_points[x].frequency = float(xml_vf_points[x].get('frequency'))
            self.energy_values.vf_points[x].energy = float(xml_vf_points[x].get('energy'))
        else:
          end_point = num_points
          for x in range(end_point):
            self.energy_values.vf_points[x].voltage = 0.0
            self.energy_values.vf_points[x].frequency = 0.0
            self.energy_values.vf_points[x].energy = 0.0
    else:
      new_vf_points = [VFPoint() for x in range(num_points)]
      end_point = num_points
      if len(self.energy_values.vf_points) < end_point:
        end_point = len(self.energy_values.vf_points)
      for x in range(end_point):
        new_vf_points[x] = self.energy_values.vf_points[x]
      self.energy_values.vf_points = new_vf_points

  def power_window(self, event, soc, nocframe):
    selection = self.ip_type.get()
    if soc.IPs.ACCELERATORS.count(selection) == 0 or self.clk_region.get() == 0:
      return
    try:
      int(nocframe.vf_points_entry.get())
    except:
      return
    self.toplevel = Toplevel()
    label1 = Label(self.toplevel, text="Power Information for \"" + selection + "\"", height=0, width=50, font="TkDefaultFont 11 bold")
    label1.pack()
    entry = [Frame(self.toplevel) for x in range(int(nocframe.vf_points_entry.get()))]
    for x in range(len(entry)):
      entry[x].pack(side=LEFT)
      Label(entry[x], text="Voltage ("+str(x)+") (V)", height=0, width=20).pack(side=TOP)
      entry[x].e1 = Entry(entry[x], width=10)
      entry[x].e1.pack(side=TOP)
      Label(entry[x], text="Frequency ("+str(x)+") (MHz)", height=0, width=20).pack(side=TOP)
      entry[x].e2 = Entry(entry[x], width=10) 
      entry[x].e2.pack(side=TOP)
      Label(entry[x], text="Tot Energy ("+str(x)+") (pJ)", height=0, width=20).pack(side=TOP)
      entry[x].e3 = Entry(entry[x], width=10) 
      entry[x].e3.pack(side=TOP)
      entry[x].e1.delete(0, END)
      entry[x].e2.delete(0, END)
      entry[x].e3.delete(0, END)
      entry[x].e1.insert(0, str(self.energy_values.vf_points[x].voltage))
      entry[x].e2.insert(0, str(self.energy_values.vf_points[x].frequency))
      entry[x].e3.insert(0, str(self.energy_values.vf_points[x].energy))
      Label(entry[x], height=1).pack(side=TOP)
    self.toplevel.entry = entry
    self.center(self.toplevel)
    self.toplevel.protocol("WM_DELETE_WINDOW", functools.partial(self.on_closing, toplevel=self.toplevel))

  def on_closing(self, toplevel):
    if messagebox.askyesno("Save", "Do you want to save the modifications?"):
      for x in range(len(self.energy_values.vf_points)):
        self.energy_values.vf_points[x].voltage = float(toplevel.entry[x].e1.get())
        self.energy_values.vf_points[x].frequency = float(toplevel.entry[x].e2.get())
        self.energy_values.vf_points[x].energy = float(toplevel.entry[x].e3.get())
    toplevel.destroy()

  def __init__(self, top, x, y):
    self.row = x
    self.col = y
    self.ip_type = StringVar()
    self.clk_region = IntVar()
    self.has_pll = IntVar()
    self.has_clkbuf = IntVar()
    self.clk_reg_active = StringVar()
    self.label = Label(top)
    self.energy_values = None

class NoC():
  
  rows = 0
  cols = 0
  top = ""

  vf_points = 4

  topology = []

  def create_topology(self, top, _R, _C): 
    self.top = top
    new_topology = []
    for y in range(_R):
      new_topology.append([])
      for x in range(_C):
        new_topology[y].append(Tile(top, y, x))
        if x < self.cols and y < self.rows:
          new_topology[y][x].ip_type.set(self.topology[y][x].ip_type.get())
          new_topology[y][x].clk_region.set(self.topology[y][x].clk_region.get())
          new_topology[y][x].has_pll.set(self.topology[y][x].has_pll.get())
          new_topology[y][x].has_clkbuf.set(self.topology[y][x].has_clkbuf.get())
          new_topology[y][x].energy_values = self.topology[y][x].energy_values
    self.topology = new_topology
    self.rows = _R
    self.cols = _C

  def get_clk_regions(self):
    regions = []
    for y in range(0, self.rows): 
      for x in range(0, self.cols): 
         tile = self.topology[y][x]
         if tile.clk_region is not None and regions.count(tile.clk_region.get()) == 0:
           regions.append(tile.clk_region.get())
    return regions

  def get_clkbuf_num(self, soc):
    tot_clkbuf = 0
    for y in range(0, self.rows): 
      for x in range(0, self.cols): 
         tile = self.topology[y][x]
         selection = tile.ip_type.get()
         if soc.IPs.ACCELERATORS.count(selection) and tile.has_clkbuf.get() == 1:
            tot_clkbuf += 1
    return tot_clkbuf

  def has_dvfs(self):
    regions = []
    for y in range(0, self.rows): 
      for x in range(0, self.cols): 
         tile = self.topology[y][x]
         if tile.clk_region is not None and tile.clk_region.get() != 0:
           return True
    return False

  def get_cpu_num(self, soc):
    tot_cpu = 0
    for y in range(0, self.rows): 
      for x in range(0, self.cols): 
         tile = self.topology[y][x]
         selection = tile.ip_type.get()
         if soc.IPs.PROCESSORS.count(selection):
            tot_cpu += 1
    return tot_cpu

  def get_acc_num(self, soc):
    tot_acc = 0
    for y in range(0, self.rows): 
      for x in range(0, self.cols): 
         tile = self.topology[y][x]
         selection = tile.ip_type.get()
         if soc.IPs.ACCELERATORS.count(selection):
            tot_acc += 1
    return tot_acc

  def get_mem_num(self, soc):
    tot_mem = 0
    tot_mem_debug = 0
    for y in range(0, self.rows): 
      for x in range(0, self.cols): 
         tile = self.topology[y][x]
         selection = tile.ip_type.get()
         if soc.IPs.MEM.count(selection):
            tot_mem += 1
            if selection == "mem_dbg":
              tot_mem_debug += 1
    return (tot_mem, tot_mem_debug)

  # WARNING: Geometry in this class only uses x=rows, y=cols, but socmap uses y=row, x=cols!
  def __init__(self):
    self.cols = 0
    self.rows = 0
    self.monitor_ddr = IntVar()
    self.monitor_inj = IntVar()
    self.monitor_routers = IntVar()
    self.monitor_accelerators = IntVar()
    self.monitor_dvfs = IntVar()

#NoC configuration frame (middle)
class NoCFrame(Pmw.ScrolledFrame):

  current_nocx = 0
  current_nocy = 0

  noc_tiles = []
  row_frames = []

  def changed(self,*args):
    if isInt(self.ROWS.get()) == False or isInt(self.COLS.get()) == False:
       return
    for y in range(0, int(self.ROWS.get())): 
      for x in range(0, int(self.COLS.get())):
         self.noc.topology[y][x].update_tile(self.soc)
    self.update_msg()

  def update_frame(self):
    if self.noc.cols > 0 and self.noc.rows > 0:
       self.COLS.insert(0, str(self.noc.cols))
       self.ROWS.insert(0, str(self.noc.rows))
    self.create_noc()
    self.changed()

  def create_tile(self, frame, tile):
    #computing the width of the widget
    list_items = tuple(self.soc.IPs.EMPTY) + tuple(self.soc.IPs.PROCESSORS) + tuple(self.soc.IPs.MISC) + tuple(self.soc.IPs.MEM) + tuple(self.soc.IPs.ACCELERATORS)
    width = 0
    for x in range(0, len(list_items)):
      if len(list_items[x]) > width: 
        width = len(list_items[x])
    #creating tile
    Pmw.OptionMenu(frame, menubutton_font="TkDefaultFont 8", 
                   menubutton_textvariable=tile.ip_type, 
                   menubutton_width = width+2,
                   items=list_items
                  ).pack()
    tile.label = Label(frame, text=tile.ip_type.get()) 
    tile.label.config(height=4,bg='white', width=30)
    tile.label.pack()
    tile.label.bind("<Double-Button-1>", lambda event:tile.power_window(event, self.soc, self))
    Label(frame, text="Clk Reg: ").pack(side=LEFT)
    tile.clk_reg_selection = Spinbox(frame, from_=0, to=len(self.soc.IPs.PROCESSORS)+len(self.soc.IPs.ACCELERATORS),wrap=True,textvariable=tile.clk_region,width=3);
    tile.clk_reg_selection.pack(side=LEFT)
    tile.pll_selection = Checkbutton(frame, text="Has PLL", variable=tile.has_pll, onvalue = 1, offvalue = 0, command=self.changed);
    tile.pll_selection.pack(side=LEFT)
    tile.clkbuf_selection = Checkbutton(frame, text="CLK BUF", variable=tile.has_clkbuf, onvalue = 1, offvalue = 0, command=self.changed);
    tile.clkbuf_selection.pack(side=LEFT)
    try:
      int(self.vf_points_entry.get())
      tile.load_characterization(self.soc, int(self.vf_points_entry.get()))
    except:
      pass

  def __init__(self, soc, bottom_frame):
    self.soc = soc
    self.noc = self.soc.noc
    #configuration frame
    self.noc_config_frame = Frame(bottom_frame)
    Label(self.noc_config_frame, text="NoC configuration", font="TkDefaultFont 11 bold").pack(side = TOP)
    self.config_noc_frame = Frame(self.noc_config_frame)
    self.config_noc_frame.pack(side=TOP)
    Label(self.config_noc_frame, text="Rows: ").pack(side = LEFT)
    self.ROWS = Entry(self.config_noc_frame, width=3)
    self.ROWS.pack(side = LEFT)
    Label(self.config_noc_frame, text="Cols: ").pack(side = LEFT)
    self.COLS = Entry(self.config_noc_frame, width=3)
    self.COLS.pack(side = LEFT)
    Button(self.noc_config_frame, text = "Config", command=self.create_noc).pack(side=TOP)

    Label(self.noc_config_frame, height=1).pack()
    Checkbutton(self.noc_config_frame, text="Monitor DDR bandwidth", variable=self.noc.monitor_ddr, anchor=W, width=20).pack()
    Checkbutton(self.noc_config_frame, text="Monitor injection rate", variable=self.noc.monitor_inj, anchor=W, width=20).pack()
    Checkbutton(self.noc_config_frame, text="Monitor router ports", variable=self.noc.monitor_routers, anchor=W, width=20).pack()
    self.monitor_acc_selection = Checkbutton(self.noc_config_frame, text="Monitor accelerator status", variable=self.noc.monitor_accelerators, anchor=W, width=20)
    self.monitor_acc_selection.pack()
    self.monitor_dvfs_selection = Checkbutton(self.noc_config_frame, text="Monitor DVFS", variable=self.noc.monitor_dvfs, width=20, anchor=W)
    self.monitor_dvfs_selection.pack()

    #statistics
    Label(self.noc_config_frame, height=1).pack()
    self.TOT_CPU = Label(self.noc_config_frame, anchor=W, width=20)
    self.TOT_MEM = Label(self.noc_config_frame, anchor=W, width=25)
    self.TOT_MISC = Label(self.noc_config_frame, anchor=W, width=20)
    self.TOT_ACC = Label(self.noc_config_frame, anchor=W, width=20)
    self.TOT_IVR = Label(self.noc_config_frame, anchor=W, width=20)
    self.TOT_CLKBUF = Label(self.noc_config_frame, anchor=W, width=20)
    self.TOT_CPU.pack(side=TOP, fill=BOTH)
    self.TOT_MEM.pack(side=TOP, fill=BOTH)
    self.TOT_MISC.pack(side=TOP, fill=BOTH)
    self.TOT_ACC.pack(side=TOP, fill=BOTH)
    Label(self.noc_config_frame, height=1).pack()
    self.TOT_IVR.pack(side=TOP, fill=BOTH)
    Label(self.noc_config_frame, height=1).pack()
    self.TOT_CLKBUF.pack(side=TOP, fill=BOTH)

    Label(self.noc_config_frame, height=1).pack()

    self.vf_frame = Frame(self.noc_config_frame)
    self.vf_frame.pack(side=TOP, fill=BOTH)
    Label(self.vf_frame, anchor=W, width=10, text=" VF points: ").pack(side=LEFT)
    self.vf_points_entry = Entry(self.vf_frame, width=3)
    self.vf_points_entry.pack(side=LEFT)
    self.vf_points_entry.delete(0, END)
    self.vf_points_entry.insert(0, "4")

    #frame for the tiles
    Pmw.ScrolledFrame.__init__(self, bottom_frame,
           labelpos = 'n',
           label_text = 'NoC Tile Configuration',
           label_font="TkDefaultFont 11 bold",
           usehullsize = 1,
           horizflex='expand',
           hull_width = 400,
           hull_height = 300,)
    self.noc_frame = self.interior()

  def update_msg(self):
    self.done.config(state=DISABLED)
    try:
      tot_cpu = self.noc.get_cpu_num(self.soc)
      tot_io = 0
      tot_clkbuf = self.noc.get_clkbuf_num(self.soc)
      (tot_mem, tot_mem_debug) = self.noc.get_mem_num(self.soc)
      tot_acc = self.noc.get_acc_num(self.soc)
      regions = self.noc.get_clk_regions()
      for y in range(0, self.noc.rows): 
        for x in range(0, self.noc.cols): 
           tile = self.noc.topology[y][x]
           selection = tile.ip_type.get()
           if self.soc.IPs.MISC.count(selection):
              tot_io += 1
      #update statistics
      self.TOT_CPU.config(text=" Num CPUs: " + str(tot_cpu))
      self.TOT_MEM.config(text=" Num memory controllers: " + str(tot_mem))
      self.TOT_MISC.config(text=" Num I/O tiles: " + str(tot_io))
      self.TOT_ACC.config(text=" Num accelerators: " + str(tot_acc))
      self.TOT_IVR.config(text=" Num CLK regions: " + str(len(regions)))
      self.TOT_CLKBUF.config(text=" Num CLKBUF: " + str(tot_clkbuf))
      clkbuf_ok = True
      if tot_clkbuf <= 9:
         self.TOT_CLKBUF.config(fg="black")
      else:
         clkbuf_ok = False
         self.TOT_CLKBUF.config(fg="red")

      if self.soc.noc.get_acc_num(self.soc) > 0:
        self.monitor_acc_selection.config(state=NORMAL)
      else:
        self.monitor_acc_selection.config(state=DISABLED)
        self.noc.monitor_accelerators.set(0)

      if self.soc.noc.has_dvfs():
        self.monitor_dvfs_selection.config(state=NORMAL)
        self.vf_points_entry.config(state=NORMAL)
      else:
        self.monitor_dvfs_selection.config(state=DISABLED)
        self.vf_points_entry.config(state=DISABLED)
        self.noc.monitor_dvfs.set(0)

      pll_string = ""
      num_pll = [0 for x in range(self.noc.cols * self.noc.rows)]
      num_components = [0 for x in range(self.noc.cols * self.noc.rows)]
      for y in range(0, self.noc.rows): 
        for x in range(0, self.noc.cols): 
           tile = self.noc.topology[y][x]
           selection = tile.ip_type.get()
           if self.soc.IPs.EMPTY.count(selection) == 0:
             num_components[tile.clk_region.get()] += 1
           if tile.has_pll.get() == 1:
             num_pll[tile.clk_region.get()] += 1
      pll_ok = True
      for x in range(len(regions)):
        if num_pll[x] == 0 and x > 0 and num_components[x] > 0:
          pll_ok = False
          pll_string += "Region \"" + str(x) + "\" requires at least one PLL\n"
        if num_pll[x] > 1 and x > 0:
          pll_ok = False
          pll_string += "Region \"" + str(x) + "\" cannot have more than one PLL\n"

      #update message box
      self.message.delete(0.0, END)
      if tot_mem >= 2 or len(regions) >= 1:
        self.cfg_frame.sync_label.config(text="With synchronizers",fg="green")
      else:
        self.cfg_frame.sync_label.config(text="No synchronizers", fg="black")
      if tot_cpu == 1 and tot_mem_debug == 1 and tot_mem <= 2 and tot_io == 1 and pll_ok == True and clkbuf_ok == True:
         self.done.config(state=NORMAL)
      else:
         string = ""
         if (tot_cpu == 0):
            string += "At least one CPU is required\n"
         if (tot_io == 0):
            string += "At least I/O tile is required\n"
         if (tot_mem_debug == 0):
            string += "At least one \"mem_dbg\" tile is required.\n"
         if (tot_cpu > 1):
            string += "Multiple CPUs are currently not supported\n"
         if (tot_io > 1):
            string += "Multiple I/O tiles are not supported\n"
         if (tot_mem_debug > 1):
            string += "Multiple \"mem_dbg\" tiles are not supported.\n"
         if (tot_mem > 2):
            string += "Maximum number of supported memory controllers is 2.\n"
         if (tot_clkbuf > 9):
            string += "The FPGA board supports no more than 9 CLKBUF's.\n"
         string += pll_string
         self.message.insert(0.0, string)
    except:
      pass

  def set_message(self, message, cfg_frame, done):
    self.message = message
    self.cfg_frame = cfg_frame
    self.done = done

  def create_noc(self):
    self.pack(side=LEFT,fill=BOTH,expand=YES)
    if isInt(self.ROWS.get()) == False or isInt(self.COLS.get()) == False:
       return
    #destroy current topology
    if len(self.row_frames) > 0:
      for x in range(0, len(self.row_frames)): 
        self.row_frames[x].destroy()
      self.noc_tiles = []
      self.row_frames = []
    #create new topology
    self.noc.create_topology(self.noc_frame, int(self.ROWS.get()), int(self.COLS.get()))
    for y in range(0, int(self.ROWS.get())): 
      self.row_frames.append(Frame(self.noc_frame, borderwidth=2, relief=RIDGE))
      self.row_frames[y].pack(side=TOP)
      self.noc_tiles.append([])
      for x in range(0, int(self.COLS.get())):
        self.noc_tiles[y].append(Frame(self.row_frames[y], borderwidth=2, relief=RIDGE))
        self.noc_tiles[y][x].pack(side=LEFT)
        Label(self.noc_tiles[y][x], text="("+str(y)+","+str(x)+")").pack()
        self.create_tile(self.noc_tiles[y][x], self.noc.topology[y][x])
        if len(self.noc.topology[y][x].ip_type.get()) == 0:
          self.noc.topology[y][x].ip_type.set("empty") # default value
    #set call-backs and default value
    for y in range(0, int(self.ROWS.get())): 
      for x in range(0, int(self.COLS.get())):
        tile = self.noc.topology[y][x]
        tile.ip_type.trace('w', self.changed)
        tile.clk_region.trace('w', self.changed)
    self.changed()
