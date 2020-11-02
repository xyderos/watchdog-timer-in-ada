pragma Task_Dispatching_Policy(FIFO_Within_Priorities);

with Ada.Text_IO; use Ada.Text_IO;

with Ada.Float_Text_IO;

with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Ada.Real_Time; use Ada.Real_Time;

procedure OverloadDetection is

    package Duration_IO is new Ada.Text_IO.Fixed_IO(Duration);

    package Int_IO is new Ada.Text_IO.Integer_IO(Integer);

    Start : constant Time := Clock; -- Start Time of the System

    --Calibrator: constant Integer := 1208; -- Calibration for correct timing

    Calibrator: constant Integer := 1000; -- Calibration for correct timing

    --Calibrator: constant Integer := 1400; -- Calibration for correct timing

    -- ==> Change parameter for your architecture!

    Warm_Up_Time: constant Integer := 100; -- Warmup time in milliseconds

    HyperperiodLength: Time_Span := Milliseconds(1200);

    CurrentHyperperiod: Integer := 1;

    NextHyperperiod: Time:= Start + HyperperiodLength + Milliseconds(Warm_Up_Time);

    -- Conversion Function: Time_Span to Float
    function To_Float(TS : Time_Span) return Float is

        SC : Seconds_Count;

        Frac : Time_Span;

    begin

        Split(Time_Of(0, TS), SC, Frac);

        return Float(SC) + Time_Unit * Float(Frac/Time_Span_Unit);

    end To_Float;

    -- Function F is a dummy function that is used to model a running user program.
    function F(N : Integer) return Integer;

    function F(N : Integer) return Integer is

        X : Integer := 0;

    begin

        for Index in 1..N loop

            for I in 1..500 loop

            X := X + I;

            end loop;

        end loop;

        return X;
    end F;

    -- Workload Model for a Parametric Task
    
    task type T(Id: Integer; Prio: Integer; Phase: Integer; Period : Integer; 
    
    Computation_Time : Integer; Relative_Deadline: Integer; Color : Integer) is
    
        pragma Priority(Prio); -- A higher number gives a higher priority
    
    end;
    
    --has the highest priority
    task Watchdog is
        
        pragma Priority(60);
        
        entry SignalOk;
    
    end Watchdog;

       --lower priority
    task Overload is
        
        pragma Priority(2);

        entry check(c: in Integer; clk : in Time);
    
    end Overload;

    task body Watchdog is

        Release : Time;
    
        CounterPreloadValue : constant Integer := 9;
    
        Counter : Integer := CounterPreloadValue;
    
    begin
    
        Release := Clock + Milliseconds(Warm_Up_Time);
    
        delay until Release;
    
        Put_Line("Watchdog timer started");
    
        loop
    
            Release := Release + Milliseconds(1200);
    
            -- When the counter reaches 0, issue a warning.
    
            if (Counter = 0) then
    
                Counter := CounterPreloadValue;
    
            end if;
    
            select
    
                accept SignalOk do
                    
                    -- Reset counter to its preloaded value
                    
                    Put("WatchdogTimer.SignalOk received at: ");Duration_IO.Put(To_Duration(Clock - Start), 2, 3);Put(",hyperperiod counter at: " & Counter'Img);New_Line(1);

                    Overload.check(Counter, Clock);
                    
                    Counter := Counter - 1;
                
                end SignalOk;
                
            or
                    delay until Release;
            
            end select;
        
        end loop;
    
    end Watchdog;

    task body Overload is
        
        Release : Time;
        
        Deadline : Time;
    
    begin
        
        Release := Clock + Milliseconds(Warm_Up_Time);
        
        Deadline := Release + Milliseconds(1200);
        
        delay until Release;
        
        loop

            select

                accept check(c: in Integer; clk : in Time) do

                    if ((c /= 1) and (clk < Deadline)) then

                        Put_Line("No overload detected for Task " & c'Img);
                       
                    elsif (c = 1 and (clk < Deadline)) then
                        
                        --entered a new hyperperiod so update the Deadline

                        Deadline := Deadline + HyperperiodLength;

                    elsif (clk > Deadline) then
                       
                        Put_Line("Overload detected for task " & c'Img);

                    end if;
                   
                end check;

            or

                delay until Release;
               
            end select;
            
        end loop;
    
    end Overload;


task body T is
      
        Next : Time;
      
        Release: Time;
      
        Completed : Time;
      
        Response : Time_Span;
      
        Average_Response : Float;
      
        Absolute_Deadline: Time;
      
        WCRT: Time_Span; -- measured WCRT (Worst Case Response Time)
      
        Dummy : Integer;
      
        Iterations : Integer;
      
        Released: Time;
      
        ColorCode : String := "[" & Trim(Color'Img, Ada.Strings.Left) & "m";
    
    begin
        
        -- Initial Release - Phase
        
        Release := Clock + Milliseconds(Phase);
        
        delay until Release;
        
        Next := Release;
        
        Iterations := 0;
        
        Average_Response := 0.0;
        
        WCRT := Milliseconds(0);

        loop
        
            Released := Clock;
        
            if (Release > NextHyperperiod) then
        
                NextHyperperiod := NextHyperperiod + HyperperiodLength;
        
                CurrentHyperperiod := CurrentHyperperiod + 1;
        
                New_Line(1);
        
            end if;
        
            Next := Release + Milliseconds(Period);
        
            Absolute_Deadline := Release + Milliseconds(Relative_Deadline);
        
            -- Simulation of User Function
        
            for I in 1..Computation_Time loop
        
                Dummy := F(Calibrator); 
        
            end loop;	
        
            Completed := Clock;
       
            Response := Completed - Release;
       
            Average_Response := (Float(Iterations) * Average_Response + To_Float(Response)) / Float(Iterations + 1);
       
            if Response > WCRT then
       
                WCRT := Response;
       
            end if;
       
            Iterations := Iterations + 1;			
      
            Put(ASCII.ESC & ColorCode);
      
            Put("H: ");
      
            Int_IO.Put(CurrentHyperperiod, 1);
     
            Put(" Task: ");
     
            Int_IO.Put(Id, 1);
     
            Put(" Period: " );
     
            Int_IO.Put(Period, 1);
     
            Put(", Release: ");
     
            Duration_IO.Put(To_Duration(Release - Start), 2, 3);
     
            Put(", Released: ");
     
            Duration_IO.Put(To_Duration(Released - Start), 2, 3);
    
            Put(", Completion: ");
    
            Duration_IO.Put(To_Duration(Completed - Start), 2, 3);
    
            Put(", Response: ");
    
            Duration_IO.Put(To_Duration(Response), 1, 3);
    
            Put(", WCRT: ");
    
            Ada.Float_Text_IO.Put(To_Float(WCRT), fore => 1, aft => 3, exp => 0);	
    
            Put(", Next Release: ");
    
            Duration_IO.Put(To_Duration(Next - Start), 2, 3);
    
            if Completed > Absolute_Deadline then 
    
                Put(" ==> Task ");
    
                Int_IO.Put(Id, 1);
    
                Put(" violates Deadline!");
    
            end if;
    
            Put(ASCII.ESC & "[00m");
    
            New_Line(1);
    
            Release := Next;

            Watchdog.signalOk;

            delay until Release;

        end loop;

    end T;


    
    -- Running Tasks
    -- NOTE: All tasks should have a minimum phase, so that they have the same time base!

    --Task_1 : T(1, 20, Warm_Up_Time, 2000, 1000, 2000); -- ID: 1
        -- Priority: 20
        --	Phase: Warm_Up_Time (100)
        -- Period 2000, 
        -- Computation Time: 1000 (if correctly calibrated) 
        -- Relative Deadline: 2000
    Task_1 : T(1, 20 - 3, Warm_Up_Time, 300, 100, 300, 33); -- ID: 1
    Task_2 : T(2, 20 - 4, Warm_Up_Time, 400, 100, 400, 31); -- ID: 2
    Task_3 : T(3, 20 - 6, Warm_Up_Time, 600, 100, 600, 32); -- ID: 3
--    Task_4 : T(4, 20 - 12, Warm_Up_Time, 1200, 200, 1200, 36); -- ID: 4

    -- Main Program: Terminates after measuring start time	
begin
    null;
end OverloadDetection;