/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package randomtopology;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 *
 * @author wens
 */
public class Randomtopology {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        final int NUM_OF_NODE = 101;
        final double GOOD_DISTANCE = 15;
        final double D0 = 1;
        Topology topology[] = new Topology[NUM_OF_NODE];
        for (int i = 0; i < NUM_OF_NODE; i++) {
            topology[i] = new Topology();
        }
        //假设
        topology[NUM_OF_NODE - 1].Setaxisx(100);
        topology[NUM_OF_NODE - 1].Setaxisy(100);
        topology[NUM_OF_NODE - 1].Setnumber(NUM_OF_NODE - 1);
        for (int i = 0; i < (NUM_OF_NODE - 1); i++) {
            boolean distance_ok = false;
            double axisx = 200 * Math.random();
            double axisy = 200 * Math.random();
            while (!distance_ok) {
                //每次只能掉落在前4个的范围内
                if (i > 4) {
                    //在i的前一半选一个点，后一半选一个点
                    /*for(int j = i-2; j <i; j++){
                     double distance2 = topology[j].Distance(axisx, axisy);
                     if(distance2 < GOOD_DISTANCE){
                     distance_ok = true;
                     break;
                     }
                     }*/
                    int random_select = i / 2;
                    int first_half = (int) (random_select * Math.random());
                    int second_half = (int) (random_select * Math.random()) + random_select;
                    if (topology[first_half].Distance(axisx, axisy) < GOOD_DISTANCE) {
                        distance_ok = true;
                    }
                    if (topology[second_half].Distance(axisx, axisy) < GOOD_DISTANCE) {
                        distance_ok = true;
                    }
                    //判断节点中是否两两距离都大于1
                    if (distance_ok == true) {
                        for (int j = 0; j < i; j++) {
                            if (topology[j].Distance(axisx, axisy) < D0) {
                                distance_ok = false;
                                break;
                            }
                        }
                        if (topology[NUM_OF_NODE - 1].Distance(axisx, axisy) < D0) {
                            distance_ok = false;
                        }
                    }
                    if (distance_ok == false) {
                        axisx = 200 * Math.random();
                        axisy = 200 * Math.random();
                    }
                }
                if (i <= 4) {
                    //记得特判断最后一个
                    for (int j = 0; j < i; j++) {
                        double distance1 = topology[j].Distance(axisx, axisy);
                        if (distance1 < GOOD_DISTANCE) {
                            distance_ok = true;
                        }
                        break;
                    }
                    //特判断最后一个
                    if (distance_ok == false) {
                        double distance0 = topology[NUM_OF_NODE - 1].Distance(axisx, axisy);
                        if (distance0 < GOOD_DISTANCE) {
                            distance_ok = true;
                        }
                    }
                    if (distance_ok == true) {
                        for (int j = 0; j < i; j++) {
                            if (topology[j].Distance(axisx, axisy) < D0) {
                                distance_ok = false;
                                break;
                            }
                        }
                        if (topology[NUM_OF_NODE - 1].Distance(axisx, axisy) < D0) {
                            distance_ok = false;
                        }
                    }
                    if (distance_ok == false) {
                        axisx = 200 * Math.random();
                        axisy = 200 * Math.random();
                    }
                }
            }
            topology[i].Setaxisx(axisx);
            topology[i].Setaxisy(axisy);
            topology[i].Setnumber(i);
            System.out.println("axisx =" + topology[i].Getaxisx() + " axisy=" + topology[i].Getasisy() + " nodenumber=" + i);
        }
        File filew = new File("randomtopology.txt");
        try {
            FileWriter outOne1 = new FileWriter(filew);
            BufferedWriter outTwo1 = new BufferedWriter(outOne1);
            for (int i = 0; i < NUM_OF_NODE; i++) {
                outTwo1.write(i + " " + topology[i].Getaxisx() + " " + topology[i].Getasisy());
                outTwo1.newLine();
            }
            outTwo1.close();
            outOne1.close();
        } catch (IOException e) {
            System.out.println(e);
        }
    }

}
