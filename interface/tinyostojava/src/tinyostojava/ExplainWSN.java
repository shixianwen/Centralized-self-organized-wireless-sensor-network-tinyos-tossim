package tinyostojava;

import java.io.*;
import java.lang.*;
import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

import se.miun.dsv.wsn.routing.SchedulableRouting;
import se.miun.dsv.wsn.util.RoutingExporter;
import se.miun.feldob.wsn.scheduling.factory.ReliabilityScheduleBuilderFactory;
import se.miun.feldob.wsn.scheduling.node.NodeBasedSchedulingAlgorithm;
import se.miun.itm.wsn.WSN;
import se.miun.itm.wsn.opt.Schedule;
import se.miun.itm.wsn.opt.repair.ShortestSinglePathCreator;
import se.miun.itm.wsn.util.StartStateGenerator;

public class ExplainWSN {

    public static void main(String[] args) throws IOException, InterruptedException, Exception {
        java.io.File markfile = new java.io.File("/home/username/Desktop/tinyos/test19/ready.txt");
        while(!markfile.exists())
         {
         System.out.println("Markfile Do not exist");
         }

        File filer = new File("/home/username/Desktop/tinyos/test19/log.txt");
        final int NUM_OF_NODES = 100;//real number of node -1
        //WSN wsn = new WSN("17.dot");
        // System.out.println(wsn.getConnectivity(0, 10));
        int[] mark = new int[200];
        double[][] testConnectivity = new double[NUM_OF_NODES][NUM_OF_NODES + 1];
        //testConnectivity[0][1] = .9;
        try {
            FileReader inOne = new FileReader(filer);
            BufferedReader inTwo = new BufferedReader(inOne);
            String s1 = null;
            while ((s1 = inTwo.readLine()) != null) {
                System.out.println(s1);
                String[] split = s1.split("\\s+");
                int x;
                x = Integer.parseInt(split[0], 16);
                int y = Integer.parseInt(split[2], 16);
                System.out.println("x=" + x);
                int length = split.length;
                        //System.out.println("split[2]+mark[x]="+split[2]+"mark"+mark[x]);
                //y =1 represent the final message of that node 
                if (y == 1) {
                    mark[x] = 1;
                    // System.out.println("split[2]+mark[x]="+split[2]+"mark1"+mark[x]);
                }
                for (int i = 5; i < length; i = i + 3) {
                    double a = (double) Integer.parseInt(split[i + 1], 16) / 255;
                    if (a != 0) {
                        testConnectivity[x][Integer.parseInt(split[i], 16)] = (double) Integer.parseInt(split[i + 1], 16) / 255;
                        if (Integer.parseInt(split[i], 16) != (NUM_OF_NODES)) {
                            testConnectivity[Integer.parseInt(split[i], 16)][x] = testConnectivity[x][Integer.parseInt(split[i], 16)];
                        }
                        System.out.println("testConnectivity[" + x + "][" + Integer.parseInt(split[i], 16) + "]=" + testConnectivity[x][Integer.parseInt(split[i], 16)]);
                    }
                }
                int count = 0;
                for (int i = 0; i < 200; i++) {
                    if (mark[i] == 1) {
                        count++;
                    }
                }
                System.out.println("count=" + count);
                        //System.out.println("length="+length);
                //for(String each : split) {
                //  System.out.println("'" + each + "'");
                //}
                //char[] tempo = new char[100];
                //tempo = s1.toCharArray();
                //System.out.println(tempo);
                //System.out.println(tempo[0]);

            }
        } catch (IOException e) {
            System.out.println(e);
        }
        File filew1 = new File("testconnectivity.txt");
        try {
            FileWriter outOne1 = new FileWriter(filew1);
            BufferedWriter outTwo1 = new BufferedWriter(outOne1);

            for (int i = 0; i < NUM_OF_NODES; i++) {
                for (int j = 0; j <= NUM_OF_NODES; j++) {

                    outTwo1.write(Double.toString(testConnectivity[i][j]));
                    if (j != NUM_OF_NODES) {
                        outTwo1.write(' ');
                    }
                }
                outTwo1.newLine();

            }
            outOne1.close();
            outTwo1.close();
        } catch (IOException e) {
            System.out.println(e);
        }
        //here we take distans into account
        File filer2 = new File("topology.txt");
        Topology topology[] = new Topology[NUM_OF_NODES + 1];
        for (int i = 0; i <= NUM_OF_NODES; i++) {
            topology[i] = new Topology();
        }
        try {
            FileReader topoone = new FileReader(filer2);
            BufferedReader toporead = new BufferedReader(topoone);
            String topos = null;
            while ((topos = toporead.readLine()) != null) {
                System.out.println(topos);
                if (topos.equals("")) {
                    break;
                }
                String[] toposplit = topos.split("\\s+");
                int number = Integer.parseInt(toposplit[0]);
                double axisx = Double.parseDouble(toposplit[1]);
                double axisy = Double.parseDouble(toposplit[2]);
                System.out.println("number=" + number + "axisx=" + axisx + "axisy=" + axisy);
                topology[number].Setaxisx(axisx);
                topology[number].Setaxisy(axisy);
                topology[number].Setnumber(number);

            }
            for (int i = 0; i < NUM_OF_NODES; i++) {
                for (int j = 0; j <= NUM_OF_NODES; j++) {
                    double distance = 0;
                    distance = topology[i].Distance(topology[j].Getaxisx(), topology[j].Getasisy());

                    if ((30 <= distance)&&(distance >= 60)) {
                                   // System.out.println(distance);

                        if (testConnectivity[i][j] > 0) {
                            System.out.println("testConnectivity[" + i + "][" + j + "] become =" + testConnectivity[i][j]);
                        }
                        testConnectivity[i][j] = 0.01;
                    }
                    if(distance >= 60){
                        testConnectivity[i][j] = 0;
                    }
                }
            }
            topoone.close();
            toporead.close();
        } catch (IOException e) {
            System.out.println(e);
        }

        WSN wsnNew = new WSN(testConnectivity);
        wsnNew.export("testFile.txt", true, false, false);

        double reliability = 0.9;

        ReliabilityScheduleBuilderFactory scheduleFactory = new ReliabilityScheduleBuilderFactory(wsnNew, reliability, true);

        // create routing (heuristic)
        ShortestSinglePathCreator creator = new ShortestSinglePathCreator(wsnNew);
        SchedulableRouting routing = creator.getWeightedShortestPath();

        Integer parent = routing.getParentFor(1, 1);//method to get my parent node
        //System.out.println(parent);  
        RoutingExporter.toBoolean(routing, "testRouting.txt");
        int[] startState = StartStateGenerator.generate(wsnNew);

        NodeBasedSchedulingAlgorithm scheduler = new NodeBasedSchedulingAlgorithm(wsnNew, scheduleFactory);

        /*for (Integer transceiver : wsnNew.getTransceivers()) {
         Integer p = routing.getParentFor(transceiver, transceiver);
         if (wsnNew.getConnectivity(transceiver, p) <0.3 || wsnNew.getConnectivity(p, transceiver) <0.3) {
         Double ab =wsnNew.getConnectivity(transceiver, p);
         System.out.println("ab="+ab);
         throw new Exception(transceiver +p+ab+"Network not appropriate.");
         }
         }*/
        Schedule s = scheduler.getSchedule(routing, startState, 1);
        //BEGIN TO WRITE INTO THE SCHEDULE.TXT
        File filew = new File("/home/username/Desktop/tinyos/test19/schedule.txt");
        try {
            FileWriter outOne = new FileWriter(filew);
            BufferedWriter outTwo = new BufferedWriter(outOne);
            for (int i = 0; i < NUM_OF_NODES; i++) {
                String schedule = null;
                int mother = routing.getParentFor(i, i);
                Set<Integer> slots = s.getSlotsForSensor(i);
                int framelength = s.size();
                int slotslength = slots.size();
                String output = null;
                if (slotslength <= 8) {
                    //enough to contain in one serialtest msg. maximun 8
                    output = Integer.toString(i) + " ";//my address
                    output = output + Integer.toString(mother) + " ";//mother node
                    output = output + "10" + " ";//tdma start time
                    output = output + Integer.toString(framelength) + " ";
                    output = output + Integer.toString(slotslength) + " ";
                    //System.out.println(output);
                    Iterator it = slots.iterator();
                    while (it.hasNext()) {
                        output = output + Integer.toString((int) it.next()) + " ";
                    }
                    System.out.println(output);
                    outTwo.write(output);
                    outTwo.newLine();
                } else {
                    int countnumber = 0;
                    output = Integer.toString(i) + " ";//my address
                    output = output + Integer.toString(mother) + " ";//mother node
                    output = output + "10" + " ";//tdma start time
                    output = output + Integer.toString(framelength) + " ";
                    Iterator it = slots.iterator();
                    String output1 = " ";
                    while (it.hasNext()) {
                        output1 = output1 + Integer.toString((int) it.next()) + " ";
                        countnumber++;
                        if (countnumber == 8) {
                            System.out.println(output + countnumber + output1);
                            outTwo.write(output + countnumber + output1);
                            outTwo.newLine();
                            countnumber = 0;
                            output1 = " ";
                            if (!it.hasNext()) {
                                break;
                            }
                        }
                    }
                    if (countnumber != 0) {
                        System.out.println(output + countnumber + output1);
                        outTwo.write(output + countnumber + output1);
                        outTwo.newLine();
                    }

                }
                //System.out.println("mother"+mother);
            }
            outTwo.close();
            outOne.close();
            markfile.delete();
        } catch (IOException e) {
            System.out.println(e);
        }

        System.out.println(s);//frame structure
        System.out.println(s.size());//frame length
        Set<Integer> slots = s.getSlotsForSensor(13); //method to get slots for certain nodes
        System.out.println(slots.size());//numberof slots
        System.out.println(slots);//what these slots is
    }
}
