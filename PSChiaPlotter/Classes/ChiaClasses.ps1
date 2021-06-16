Add-Type @"
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Collections.ObjectModel;
using System.Runtime.CompilerServices;
using System.ComponentModel;
using System.Windows.Input;
using System.Diagnostics;
using System.Windows;
using System.Text.RegularExpressions;

namespace PSChiaPlotter
{
    public class ChiaParameters : INotifyPropertyChanged
    {
        private int _ram;
        private ChiaVolume _secondtempvolume;
        private ChiaKSize _ksize;
        private string _logdirectory;

        public ChiaKSize KSize
        {
            get { return _ksize; }
            set
            {
                _ksize = value;
                OnPropertyChanged();
            }
        }
        public int RAM
        {
            get { return _ram; }
            set
            {
                _ram = value;
                OnPropertyChanged();
                
            }
        }
        public int Threads { get; set; }
        public int Buckets { get; set; }
        public ChiaVolume TempVolume { get; set; }
        public ChiaVolume SecondTempVolume
        {
            get { return _secondtempvolume; }
            set
            {
                _secondtempvolume = value;
                OnPropertyChanged();
            }
        }
        public ChiaVolume FinalVolume { get; set; }
        public string LogDirectory
        {
            get { return _logdirectory; }
            set
            {
                _logdirectory = value;
                OnPropertyChanged();
            }
        }
        public bool DisableBitField { get; set; }
        public bool ExcludeFinalDirectory { get; set; }

        public string PoolPublicKey { get; set; }
        public string FarmerPublicKey { get; set; }

        public string BasicTempDirectory { get; set; }
        public string BasicFinalDirectory { get; set; }
        public string BasicSecondTempDirectory { get; set; }
        public bool EnableBasicSecondTempDirectory { get; set; }

        public ChiaParameters()
        {
            KSize = new ChiaKSize(32);
            RAM = 3390;
            Threads = 2;
            Buckets = 128;
            LogDirectory = System.IO.Path.Combine(System.Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".chia\\mainnet\\plotter");
        }
        public ChiaParameters(ChiaKSize ksize,int ram,int threads,string logdir)
        {
            KSize = ksize;
            RAM = ram;
            Threads = threads;
            LogDirectory = logdir;
            DisableBitField = true;
            ExcludeFinalDirectory = true;
            EnableBasicSecondTempDirectory = false;
        }
        public ChiaParameters(ChiaParameters chiaParameters)
        {
            KSize = chiaParameters.KSize;
            RAM = chiaParameters.RAM;
            Threads = chiaParameters.Threads;
            LogDirectory = chiaParameters.LogDirectory;
            DisableBitField = chiaParameters.DisableBitField;
            ExcludeFinalDirectory = chiaParameters.ExcludeFinalDirectory;
            PoolPublicKey = chiaParameters.PoolPublicKey;
            FarmerPublicKey = chiaParameters.FarmerPublicKey;
            Buckets = chiaParameters.Buckets;
            EnableBasicSecondTempDirectory = chiaParameters.EnableBasicSecondTempDirectory;
            SecondTempVolume = chiaParameters.SecondTempVolume;
        }

        public event PropertyChangedEventHandler PropertyChanged;
        public void OnPropertyChanged([CallerMemberName] string caller = null)
        {
            var handler = PropertyChanged;
            if (handler != null)
            {
                handler(this, new PropertyChangedEventArgs(caller));
            }
        }
    }

    public class ChiaJob : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;
        private string _jobname;
        private int _progress;
        private TimeSpan _runtime;
        private TimeSpan _esttimeremaining;
        private int _completedplotcount;
        private int _failedplotcount;
        private int _completedruncount;
        private int _queuecount;
        private ObservableCollection<ChiaRun> _runsinprogress;
        private string _status;
        private ObservableCollection<ChiaVolume> _tempvolumes;
        private ObservableCollection<ChiaVolume> _finalvolumes;
        private bool _ignoremaxparallel;
        private ChiaParameters _initialchiaparameters;
        private bool _enablephaseonelimitor;
        private int _phaseonelimit;
        private bool _queuelooping;

        public int JobNumber { get; set; }
        public string JobName
        {
            get { return _jobname; }
            set
            {
                _jobname = value;
                OnPropertyChanged();
            }
        }
        public bool IgnoreMaxParallel
        {
            get { return _ignoremaxparallel; }
            set
            {
                _ignoremaxparallel = value;
                OnPropertyChanged();
            }
        }
        public string Status
        {
            get { return _status; }
            set
            {
                _status = value;
                OnPropertyChanged();
            }
        }
        public int TotalPlotCount { get; set; }
        public ObservableCollection<ChiaRun> RunsInProgress
        {
            get { return _runsinprogress; }
            set
            {
                _runsinprogress = value;
                OnPropertyChanged();
            }
        }

        public bool QueueLooping
        {
            get
            {
                return _queuelooping;
            }
            set
            {
                _queuelooping = value;
                OnPropertyChanged();
            }
        }

        public int PhaseOneLimit
        {
            get { return _phaseonelimit; }
            set
            {
                _phaseonelimit = value;
                OnPropertyChanged();
            }
        }
        public bool EnablePhaseOneLimitor
        {
            get { return _enablephaseonelimitor; }
            set
            {
                _enablephaseonelimitor = value;
                OnPropertyChanged();
            }
        }
        public int CompletedPlotCount
        {
            get { return _completedplotcount; }
            set
            {
                _completedplotcount = value;
                OnPropertyChanged();
            }
        }

        public int FailedPlotCount
        {
            get { return _failedplotcount; }
            set
            {
                _failedplotcount = value;
                OnPropertyChanged();
            }
        }

        public int CompletedRunCount
        {
            get { return _completedruncount; }
            set
            {
                _completedruncount = value;
                if (CompletedRunCount == TotalPlotCount)
                {
                    Status = "Completed";
                }
                OnPropertyChanged();
            }
        }
        public int QueueCount
        {
            get { return _queuecount; }
            set
            {
                _queuecount = value;
                OnPropertyChanged();
            }
        }
        public int Progress
        {
            get { return _progress; }
            set
            {
                _progress = value;
                OnPropertyChanged();
            }
        }

        public bool BasicPlotting { get; set; }

        public ChiaParameters InitialChiaParameters
        {
            get { return _initialchiaparameters; }
            set
            {
                _initialchiaparameters = value;
                OnPropertyChanged();
            }
        }
        public ObservableCollection<ChiaVolume> TempVolumes
        {
            get { return _tempvolumes; }
            set
            {
                _tempvolumes = value;
                OnPropertyChanged();
            }
        }
        public ObservableCollection<ChiaVolume> FinalVolumes
        {
            get { return _finalvolumes; }
            set
            {
                _finalvolumes = value;
                OnPropertyChanged();
            }
        }

        public DateTime StartTime { get; set; }
        public TimeSpan RunTime
        {
            get { return _runtime; }
            set
            {
                _runtime = value;
                OnPropertyChanged();
            }
        }
        public TimeSpan EstTimeRemaining
        {
            get { return _esttimeremaining; }
            set
            {
                _esttimeremaining = value;
                OnPropertyChanged();
            }
        }
        public ObservableCollection<ChiaQueue> Queues { get; set; }
        public int DelayInMinutes { get; set; }
        public int FirstDelay { get; set; }


        public ChiaJob()
        {
            StartTime = DateTime.Now;
            InitialChiaParameters = new ChiaParameters();
            QueueCount = 1;
            TotalPlotCount = 1;
            FirstDelay = 0;
            DelayInMinutes = 60;
            BasicPlotting = false;
            Queues = new ObservableCollection<ChiaQueue>();
            RunsInProgress = new ObservableCollection<ChiaRun>();
            TempVolumes = new ObservableCollection<ChiaVolume>();
            FinalVolumes = new ObservableCollection<ChiaVolume>();
            QueueLooping = false;
        }

        public void OnPropertyChanged([CallerMemberName] string caller = null)
        {
            var handler = PropertyChanged;
            if (handler != null)
            {
                handler(this, new PropertyChangedEventArgs(caller));
            }
        }
    }

    public class ChiaQueue : INotifyPropertyChanged
    {
        private int _completedplotcount;
        private int _failedplotcount;
        private string _status;
        private DateTime _starttime;
        private string _buttoncontent;
        private ChiaRun _currentrun;
        private bool _buttonenabled;
        private DateTime _currenttime;
        private TimeSpan _runtime;
        private bool _quitbuttonenabled;
        private bool _quit;
        private bool _isblocked;

        public int JobNumber { get; set; }
        public int QueueNumber { get; set; }
        public bool Pause { get; set; }

        public ChiaParameters PlottingParameters { get; set; }

        public int CompletedPlotCount
        {
            get { return _completedplotcount; }
            set
            {
                _completedplotcount = value;
                OnPropertyChanged();
            }
        }
        public int FailedPlotCount
        {
            get { return _failedplotcount; }
            set
            {
                _failedplotcount = value;
                OnPropertyChanged();
            }
        }
        public DateTime StartTime
        {
            get { return _starttime; }
            set
            {
                _starttime = value;
                OnPropertyChanged();
            }
        }
        public string Status
        {
            get { return _status; }
            set
            {
                _status = value;
                if (_status == "Finished" || _status == "Failed")
                {
                    ButtonEnabled = false;
                    QuitButtonEnabled = false;
                    CurrentRun = null;
                }
                else
                {
                    ButtonEnabled = true;
                }
                OnPropertyChanged();
            }
        }

        public bool IsBlocked
        {
            get { return _isblocked; }
            set
            {
                _isblocked = value;
                OnPropertyChanged();
            }
        }

        public DateTime CurrentTime
        {
            get { return _currenttime; }
            set
            {
                _currenttime = value;
                RunTime = _currenttime - StartTime;
            }
        }
        public TimeSpan RunTime
        {
            get { return _runtime; }
            set
            {
                _runtime = value;
                OnPropertyChanged();
            }
        }
        public int Progress { get; set; }
        public ObservableCollection<ChiaRun> Runs { get; set; }
        public ChiaRun CurrentRun
        {
            get { return _currentrun; }
            set
            {
                _currentrun = value;
                OnPropertyChanged();
            }
        }

        public ChiaJob ParentJob { get; set; }

        public bool QuitButtonEnabled
        {
            get { return _quitbuttonenabled; }
            set
            {
                _quitbuttonenabled = value;
                OnPropertyChanged();
            }
        }

        public bool Quit
        {
            get { return _quit; }
            set
            {
                _quit = value;
                OnPropertyChanged();
            }
        }

        public ChiaQueue (int queueNum, ChiaParameters parameters, ChiaJob chiajob)
        {
            ParentJob = chiajob;
            JobNumber = chiajob.JobNumber;
            QueueNumber = queueNum;
            CompletedPlotCount = 0;
            StartTime = DateTime.Now;
            Status = "Waiting";
            Progress = 0;
            Runs = new ObservableCollection<ChiaRun>();
            ButtonContent = "Pause";
            ButtonEnabled = false;
            Quit = false;
            QuitButtonEnabled = true;
            PlottingParameters = parameters;
            IsBlocked = true;
        }

        public event PropertyChangedEventHandler PropertyChanged;

        public void OnPropertyChanged([CallerMemberName] string caller = null)
        {
            var handler = PropertyChanged;
            if (handler != null)
            {
                handler(this, new PropertyChangedEventArgs(caller));
            }
        }

        public string ButtonContent
        {
            get { return _buttoncontent; }
            set
            {
                _buttoncontent = value;
                OnPropertyChanged();
            }
        }

        public bool ButtonEnabled
        {
            get { return _buttonenabled; }
            set
            {
                _buttonenabled = value;
                OnPropertyChanged();
            }
        }


        public void PauseResumeQueue()
        {
            if (Pause)
            {
                ButtonContent = "Pause";
                Status = Status.Replace(" - Pending Pause","");
                if (ParentJob.QueueLooping == false)
                {
                    IsBlocked = false;
                }
                Pause = false;
            }
            else
            {
                ButtonContent = "Resume";
                Status = Status + " - Pending Pause";
                IsBlocked = true;
                Pause = true;
            }
        }

        public void QuitQueue()
        {
            try
            {
                System.Windows.MessageBoxButton buttons = System.Windows.MessageBoxButton.YesNoCancel;
                System.Windows.MessageBoxButton buttons2 = System.Windows.MessageBoxButton.YesNo;
                System.Windows.MessageBoxImage icon = System.Windows.MessageBoxImage.Information;
                if (CurrentRun != null)
                {
                    System.Windows.MessageBoxResult response = System.Windows.MessageBox.Show("Would you like to quit the current running chia process?\nClick yes to quit the current chia process and end queue.\nClick No to let the chia process finish then end queue.", "Quit Queue", buttons, icon);
                    if (System.Windows.MessageBoxResult.Yes == response)
                    {
                        Quit = true;
                        Status = "Quitting";
                        QuitButtonEnabled = false;
                        ButtonEnabled = false;
                        IsBlocked = false;
                        if (CurrentRun != null)
                        {
                            CurrentRun.ChiaProcess.Kill();
                        }
                    }
                    else if (System.Windows.MessageBoxResult.No == response)
                    {
                        Quit = true;
                        QuitButtonEnabled = false;
                        ButtonEnabled = false;
                        IsBlocked = false;
                        Status = "Last run - Pending Quit";
                    }
                }
                else
                {
                    System.Windows.MessageBoxResult response = System.Windows.MessageBox.Show("No chia processes running under this queue, so it will be ended right away. Continue?", "Quit Queue", buttons2, icon);
                    if (System.Windows.MessageBoxResult.Yes == response)
                    {
                        Quit = true;
                        IsBlocked = false;
                        Status = "Quitting";
                        ButtonEnabled = false;
                        QuitButtonEnabled = false;
                    }
                }
            }
            catch
            {
                System.Windows.MessageBox.Show("Unable To Quit Queue");
            }
        }
    }


    public class ChiaRun : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;
        private TimeSpan _esttimeremaining;
        private double _progress;
        private TimeSpan _runtime;
        private DateTime _currenttime;
        private string _status;
        private int _tempsize;
        private string _phasse;
        private int _exitcode;
        private DateTime _exittime;
        private double _currentphaseprogress;
    
        public int JobNumber { get; set; }
        public int QueueNumber { get; set; }
        public int RunNumber { get; set; }
    
        public string PlotId { get; set; }
        public string Phase
        {
            get { return _phasse; }
            set
            {
                _phasse = value;
                OnPropertyChanged();
            }
        }
    
        public double CurrentPhaseProgress
        {
            get { return _currentphaseprogress; }
            set
            {
                _currentphaseprogress = value;
                OnPropertyChanged();
            }
        }
    
        public int TempSize
        {
            get { return _tempsize; }
            set
            {
                _tempsize = value;
                OnPropertyChanged();
            }
        }
    
        public string LogDirectory { get; set; }
        public string LogPath { get; set; }
        public int ProcessID { get; set; }
        public ChiaParameters PlottingParameters { get; set; }
    
        public string CheckPlotPowershellCommand { get; set; }
    
        public string Status
        {
            get { return _status; }
            set
            {
                _status = value;
                OnPropertyChanged();
            }
        }
        public TimeSpan EstTimeRemaining
        {
            get { return _esttimeremaining; }
            set
            {
                _esttimeremaining = value;
                OnPropertyChanged();
            }
        }
        public double Progress
        {
            get { return _progress; }
            set
            {
                _progress = value;
                OnPropertyChanged();
            }
        }
        public TimeSpan RunTime
        {
            get { return _runtime; }
            set
            {
                _runtime = value;
                EstTimeRemaining = TimeSpan.FromSeconds(Math.Round(TimeSpan.FromSeconds(Math.Round((RunTime.TotalSeconds * 100) / Progress)).TotalSeconds - RunTime.TotalSeconds));
                OnPropertyChanged();
            }
        }
        public DateTime CurrentTime
        {
            get { return _currenttime; }
            set
            {
                _currenttime = value;
                RunTime = _currenttime - ChiaProcess.StartTime;
                OnPropertyChanged();
            }
        }
    
        public int ExitCode
        {
            get { return _exitcode; }
            set
            {
                _exitcode = value;
                OnPropertyChanged();
            }
        }
        public DateTime ExitTime
        {
            get { return _exittime; }
            set
            {
                _exittime = value;
                OnPropertyChanged();
            }
        }
        public System.Diagnostics.Process ChiaProcess { get; set; }
    
        public void OnPropertyChanged([CallerMemberName] string caller = null)
        {
            var handler = PropertyChanged;
            if (handler != null)
            {
                handler(this, new PropertyChangedEventArgs(caller));
            }
        }
    
        public void OpenLogFile()
        {
            try
            {
                Process.Start(LogPath);
            }
            catch
            {
                string[] array = new string[2];
                array[0] = "Unable to open log file :( - Check here ->";
                if (string.IsNullOrEmpty(LogPath))
                {
                    array[1] = "n/a";
                }
                else
                {
                    array[1] = LogPath;
                }
                
                string message = string.Join(" ",array);
                MessageBox.Show(message);
            }
        }
    
        public void OpenLogStats()
        {
            try
            {
                string[] array = new string[4];
                array[0] = "-WindowStyle hidden -noprofile -Sta -Command Show-ChiaPlottingStatistic -LogPath ";
                array[1] = "'";
                array[2] = LogPath;
                array[3] = "'";
                string command = string.Join("", array);
                Process.Start("powershell.exe", command);
            }
            catch
            {
                string[] array = new string[2];
                array[0] = "Unable to open log file :( - Check here ->";
                if (string.IsNullOrEmpty(LogPath))
                {
                    array[1] = "n/a";
                }
                else
                {
                    array[1] = LogPath;
                }
    
                string message = string.Join(" ", array);
                MessageBox.Show(message);
            }
        }
    
        private void KillProcess()
        {
            if (ChiaProcess.HasExited)
            {
                MessageBox.Show("Process has already been killed");
            }
            else
            {
                if (MessageBox.Show("Are you sure you want to kill this plotting process?", "Kill Process Warning!", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes)
                {
                    ChiaProcess.Kill();
                }
            }
        }
    
        public void CheckPlot()
        {
            try
            {
                string command = "-noexit -noprofile -command " + CheckPlotPowershellCommand;
                Process.Start("powershell.exe",command);
            }
            catch
            {
                MessageBox.Show("Unable To Check Log File :(");
            }
        }
    
        private ICommand _killprocesscommand;
        public ICommand KillProcessCommand
        {
            get
            {
                if (_killprocesscommand == null)
                    _killprocesscommand = new RelayCommand(param => KillProcess());
                return _killprocesscommand;
            }
        }
    
        private ICommand _openlogfilecommand;
        public ICommand OpenLogFileCommand
        {
            get
            {
                if (_openlogfilecommand == null)
                    _openlogfilecommand = new RelayCommand(param => this.OpenLogFile());
                return _openlogfilecommand;
            }
        }
    
        private ICommand _openlogstatscommand;
        public ICommand OpenLogStatsCommand
        {
            get
            {
                if (_openlogstatscommand == null)
                    _openlogstatscommand = new RelayCommand(param => this.OpenLogStats());
                return _openlogstatscommand;
            }
        }
    
        private ICommand _checkplotcommand;
        public ICommand CheckPlotCommand
        {
            get
            {
                if (_checkplotcommand == null)
                   _checkplotcommand = new RelayCommand(param => this.CheckPlot());
                return _checkplotcommand;
            }
        }
        public ChiaQueue ParentQueue { get; set; }
    
        public ChiaRun(ChiaQueue chiaqueue,int runnumber, ChiaParameters chiaparameters)
        {
            ParentQueue = chiaqueue;
            JobNumber = chiaqueue.ParentJob.JobNumber;
            QueueNumber = chiaqueue.QueueNumber;
            RunNumber = runnumber;
            Progress = .41;
            PlottingParameters = chiaparameters;
        }
    
    }

    public class RelayCommand : ICommand
    {
        private Action<object> execute;
        private Func<object, bool> canExecute;

        public RelayCommand(Action<object> execute)
        {
            this.execute = execute;
            this.canExecute = null;
        }

        public RelayCommand(Action<object> execute, Func<object, bool> canExecute)
        {
            this.execute = execute;
            this.canExecute = canExecute;
        }

        public event EventHandler CanExecuteChanged
        {
            add { CommandManager.RequerySuggested += value; }
            remove { CommandManager.RequerySuggested -= value; }
        }

        public bool CanExecute(object parameter)
        {
            if (canExecute == null)
            {
                return true;
            }
            else if (parameter == null)
            {
                return false;
            }
            else
            {
                return canExecute(parameter);
            }
        }

        public void Execute(object parameter)
        {
            this.execute(parameter);
        }
    }

    public class NewJobViewModel : INotifyPropertyChanged
    {
        private ChiaJob _newchiajob;
        public ObservableCollection<ChiaVolume> TempAvailableVolumes { get; set; }
        public ObservableCollection<ChiaVolume> FinalAvailableVolumes { get; set; }
        public ObservableCollection<ChiaVolume> SecondTempVolumes { get; set; }
        public ObservableCollection<ChiaVolume> SelectedTempVolumes { get; set; }
        public ObservableCollection<ChiaVolume> SelectedFinalVolumes { get; set; }
        public ObservableCollection<ChiaKSize> AvailableKSizes { get; set; }
        public ChiaJob NewChiaJob
        {
            get { return _newchiajob; }
            set
            {
                _newchiajob = value;
                OnPropertyChanged();
            }
        }


        public event PropertyChangedEventHandler PropertyChanged;

        public void OnPropertyChanged([CallerMemberName] string caller = null)
        {
            var handler = PropertyChanged;
            if (handler != null)
            {
                handler(this, new PropertyChangedEventArgs(caller));
            }
        }

        public NewJobViewModel(ChiaJob newjob)
        {
            NewChiaJob = newjob;
            TempAvailableVolumes = new ObservableCollection<ChiaVolume>();
            FinalAvailableVolumes = new ObservableCollection<ChiaVolume>();
            SecondTempVolumes = new ObservableCollection<ChiaVolume>();

            ObservableCollection<ChiaKSize>  availableksizes = new ObservableCollection<ChiaKSize>();
            availableksizes.Add(new ChiaKSize(25));
            for (int i = 32; i <= 35; i++)
            {
                availableksizes.Add(new ChiaKSize(i));
            }
            AvailableKSizes = availableksizes;
        }

        public void AddTempVolume(ChiaVolume chiavolume)
        {
            if (TempAvailableVolumes.Contains(chiavolume))
            {
                NewChiaJob.TempVolumes.Add(chiavolume);
                TempAvailableVolumes.Remove(chiavolume);
            }
        }
        public void RemoveTempVolume(ChiaVolume chiavolume)
        {
            NewChiaJob.TempVolumes.Remove(chiavolume);
            TempAvailableVolumes.Add(chiavolume);
        }

        private ICommand _addtempvolumecommand;
        public ICommand AddTempVolumeCommand
        {
            get
            {
                if (_addtempvolumecommand == null)
                    _addtempvolumecommand = new RelayCommand(param => AddTempVolume((ChiaVolume)param));
                return _addtempvolumecommand;
            }
        }

        private ICommand _removetempvolumecommand;
        public ICommand RemoveTempVolumeCommand
        {
            get
            {
                if (_removetempvolumecommand == null)
                    _removetempvolumecommand = new RelayCommand(param => RemoveTempVolume((ChiaVolume)param));
                return _removetempvolumecommand;
            }
        }

        //Final Directory Commands
        public void AddFinalVolume(ChiaVolume chiavolume)
        {
            if (FinalAvailableVolumes.Contains(chiavolume))
            {
                NewChiaJob.FinalVolumes.Add(chiavolume);
                FinalAvailableVolumes.Remove(chiavolume);
            }
        }
        public void RemoveFinalVolume(ChiaVolume chiavolume)
        {
            NewChiaJob.FinalVolumes.Remove(chiavolume);
            FinalAvailableVolumes.Add(chiavolume);
        }

        private ICommand _addfinalvolumecommand;
        public ICommand AddFinalVolumeCommand
        {
            get
            {
                if (_addfinalvolumecommand == null)
                    _addfinalvolumecommand = new RelayCommand(param => AddFinalVolume((ChiaVolume)param));
                return _addfinalvolumecommand;
            }
        }

        private ICommand _removefinalvolumecommand;
        public ICommand RemoveFinalVolumeCommand
        {
            get
            {
                if (_removefinalvolumecommand == null)
                    _removefinalvolumecommand = new RelayCommand(param => RemoveFinalVolume((ChiaVolume)param));
                return _removefinalvolumecommand;
            }
        }
    }

    public class ChiaVolume : INotifyPropertyChanged
    {
        private string _directorypath;
        private long _freespace;
        private double _freespaceingb;
        private double _percentfree;
        private int _potentialfinalplotsremaining;
        private int _maxconcurrentchiaruns;

        public char DriveLetter { get; set; }
        public string Label { get; set; }
        public string UniqueId { get; set; }
        public long Size { get; set; }
        public double SizeInGB { get; set; }

        public long FreeSpace
        {
            get { return _freespace; }
            set
            {
                PotentialFinalPlotsRemaining = (int)Math.Floor((decimal)(value / 108877420954));
                double freespaceinGB = (double)value / 1073741824;
                double percentfree = (double)value / (double)Size * 100;
                FreeSpaceInGB = Math.Round(freespaceinGB,2);
                PercentFree = Math.Round(percentfree, 2);
                _freespace = value;
                OnPropertyChanged();
            }
        }
        public double FreeSpaceInGB
        {
            get { return _freespaceingb; }
            set
            {
                _freespaceingb = value;
                OnPropertyChanged();
            }
        }
        public double PercentFree
        {
            get { return _percentfree; }
            set
            {
                _percentfree = value;
                OnPropertyChanged();
            }
        }
        public string DiskName { get; set; }
        public bool SystemVolume { get; set; }
        public string BusType { get; set; }
        public string MediaType { get; set; }
        public List<string> AccessPaths { get; set; }
        public int PotentialFinalPlotsRemaining
        {
            get { return _potentialfinalplotsremaining; }
            set
            {
                _potentialfinalplotsremaining = value;
                OnPropertyChanged();
            }
        }
        public int MaxConCurrentTempChiaRuns
        {
            get { return _maxconcurrentchiaruns; }
            set
            {
                _maxconcurrentchiaruns = value;
                OnPropertyChanged();
            }
        }
        public ObservableCollection<ChiaRun> PendingFinalRuns { get; set; }
        public string DirectoryPath
        {
            get { return _directorypath; }
            set
            {
                _directorypath = value;
                OnPropertyChanged();
            }
        }
        public ObservableCollection<ChiaRun> CurrentChiaRuns { get; set; }


        public event PropertyChangedEventHandler PropertyChanged;

        public void OnPropertyChanged([CallerMemberName] string caller = null)
        {
            var handler = PropertyChanged;
            if (handler != null)
            {
                handler(this, new PropertyChangedEventArgs(caller));
            }
        }

        public ChiaVolume(string uniqueid, string label, long size, long freespace)
        {
            UniqueId = uniqueid;
            Label = label;
            Size = size;
            FreeSpace = freespace;
            CurrentChiaRuns = new ObservableCollection<ChiaRun>();
            PendingFinalRuns = new ObservableCollection<ChiaRun>();
            AccessPaths = new List<string>();

            double freespaceinGB = (double)freespace / 1073741824;
            double percentfree = (double)freespace / (double)size * 100;
            double sizeinGB = (double)size / 1073741824;
            SizeInGB = Math.Round(sizeinGB, 2);
            FreeSpaceInGB = Math.Round(freespaceinGB, 2);
            PercentFree = Math.Round(percentfree, 2);
            PotentialFinalPlotsRemaining = (int)Math.Floor((decimal)freespace / 108877420954);
        }
        public ChiaVolume(ChiaVolume chiavolume)
        {
            UniqueId = chiavolume.UniqueId;
            Label = chiavolume.Label;
            Size = chiavolume.Size;
            DriveLetter = chiavolume.DriveLetter;
            FreeSpace = chiavolume.FreeSpace;
            CurrentChiaRuns = new ObservableCollection<ChiaRun>();
            PendingFinalRuns = new ObservableCollection<ChiaRun>();
            AccessPaths = chiavolume.AccessPaths;
            SystemVolume = chiavolume.SystemVolume;
            BusType = chiavolume.BusType;
            MediaType = chiavolume.MediaType;
            DirectoryPath = chiavolume.DirectoryPath;
            MaxConCurrentTempChiaRuns = chiavolume.MaxConCurrentTempChiaRuns;

            double freespace = chiavolume.FreeSpace;
            double size = chiavolume.Size;
            double freespaceinGB = freespace / 1073741824;
            double percentfree = freespace / size * 100;
            double sizeinGB = size / 1073741824;
            SizeInGB = Math.Round(sizeinGB, 2);
            FreeSpaceInGB = Math.Round(freespaceinGB, 2);
            PercentFree = Math.Round(percentfree, 2);
            PotentialFinalPlotsRemaining = (int)Math.Floor((decimal)freespace / 108877420954);
        }

        public ChiaVolume(string dirpath)
        {
            DirectoryPath = dirpath;
        }

    }

    public class MainViewModel : INotifyPropertyChanged
    {
        private TimeSpan _fastestrun;
        private TimeSpan _slowestrun;
        private double _tbplottedperday;
        private double _plotsplottedperday;
        private TimeSpan _averagetime;
        private string _loglevel;

        public TimeSpan FastestRun
        {
            get { return _fastestrun; }
            set
            {
                _fastestrun = value;
                OnPropertyChanged();
            }
        }
        public TimeSpan SlowestRun
        {
            get { return _slowestrun; }
            set
            {
                _slowestrun = value;
                OnPropertyChanged();
            }
        }

        public TimeSpan AverageTime
        {
            get { return _averagetime; }
            set
            {
                _averagetime = value;
                OnPropertyChanged();
            }
        }
        public double TBPlottedPerDay
        {
            get { return _tbplottedperday; }
            set
            {
                _tbplottedperday = value;
                OnPropertyChanged();
            }
        }
        public double PlotPlottedPerDay
        {
            get { return _plotsplottedperday; }
            set
            {
                _plotsplottedperday = value;
                OnPropertyChanged();
            }
        }
        public string Version { get; set; }

        public string LogPath { get; set; }
        public string LogLevel
        {
            get { return _loglevel; }
            set
            {
                _loglevel = value;
                OnPropertyChanged();
            }
        }

        public ObservableCollection<ChiaRun> AllRuns { get; set; }
        public ObservableCollection<ChiaRun> CurrentRuns { get; set; }
        public ObservableCollection<ChiaRun> CompletedRuns { get; set; }
        public ObservableCollection<ChiaRun> FailedRuns { get; set; }

        public ObservableCollection<ChiaQueue> AllQueues { get; set; }
        public ObservableCollection<ChiaJob> AllJobs { get; set; }
        public ObservableCollection<ChiaVolume> AllVolumes { get; set; }


        public MainViewModel()
        {
            AllRuns = new ObservableCollection<ChiaRun>();
            CurrentRuns = new ObservableCollection<ChiaRun>();
            CompletedRuns = new ObservableCollection<ChiaRun>();
            FailedRuns = new ObservableCollection<ChiaRun>();
            AllQueues = new ObservableCollection<ChiaQueue>();
            AllJobs = new ObservableCollection<ChiaJob>();
            AllVolumes = new ObservableCollection<ChiaVolume>();

            System.Windows.Data.BindingOperations.EnableCollectionSynchronization(AllJobs, new System.Object());
            System.Windows.Data.BindingOperations.EnableCollectionSynchronization(AllQueues, new System.Object());
            System.Windows.Data.BindingOperations.EnableCollectionSynchronization(AllRuns, new System.Object());
            System.Windows.Data.BindingOperations.EnableCollectionSynchronization(CurrentRuns, new System.Object());
            System.Windows.Data.BindingOperations.EnableCollectionSynchronization(CompletedRuns, new System.Object());
            System.Windows.Data.BindingOperations.EnableCollectionSynchronization(FailedRuns, new System.Object());
            System.Windows.Data.BindingOperations.EnableCollectionSynchronization(AllVolumes, new System.Object());
        }


        public event PropertyChangedEventHandler PropertyChanged;

        public void OnPropertyChanged([CallerMemberName] string caller = null)
        {
            var handler = PropertyChanged;
            if (handler != null)
            {
                handler(this, new PropertyChangedEventArgs(caller));
            }
        }

        public void OpenLogFile()
        {
            try
            {
                Process.Start(LogPath);
            }
            catch
            {
                string[] array = new string[2];
                array[0] = "Unable to open log file :( - Check here ->";
                if (string.IsNullOrEmpty(LogPath))
                {
                    array[1] = "n/a";
                }
                else
                {
                    array[1] = LogPath;
                }

                string message = string.Join(" ", array);
                MessageBox.Show(message);
            }
        }

        private ICommand _openlogfilecommand;
        public ICommand OpenLogFileCommand
        {
            get
            {
                if (_openlogfilecommand == null)
                    _openlogfilecommand = new RelayCommand(param => this.OpenLogFile());
                return _openlogfilecommand;
            }
        }

    }

    public class ChiaKSize : INotifyPropertyChanged
    {
        private int _ksizevalue;
        public int KSizeValue
        {
            get { return _ksizevalue; }
            set
            {
                _ksizevalue = value;
                AdjustParameters(_ksizevalue);
                OnPropertyChanged();
            }
        }
        public long TempSize { get; private set; }
        public long FinalSize { get; private set; }
        public int MinRAM { get; private set; }
        public ChiaKSize (int ksize)
        {
            KSizeValue = ksize;
            AdjustParameters(_ksizevalue);
        }
        private void AdjustParameters (int ksizevalue)
        {
                switch (ksizevalue)
                {
                case 25:
                    TempSize = 1932735284;
                    FinalSize = 629145600;
                    MinRAM = 512;
                    break;
                case 32:
                    TempSize = 256624295936;
                    FinalSize = 108877420954;
                    MinRAM = 3390;
                    break;
                case 33:
                    TempSize = 559419490304;
                    FinalSize = 224197292851;
                    MinRAM = 7400;
                    break;
                case 34:
                    TempSize = 1117765238784;
                    FinalSize = 461494235956;
                    MinRAM = 14800;
                    break;
                case 35:
                    TempSize = 2335388467200;
                    FinalSize = 949295146599;
                    MinRAM = 29600;
                    break;
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        public void OnPropertyChanged([CallerMemberName] string caller = null)
        {
            var handler = PropertyChanged;
            if (handler != null)
            {
                handler(this, new PropertyChangedEventArgs(caller));
            }
        }
    }
}
"@ -ReferencedAssemblies PresentationFramework,PresentationCore,WindowsBase,"System.Xaml"

try{
    add-type -type  @"
	using System;
	using System.Runtime.InteropServices;
	using System.ComponentModel;
	using System.IO;
	namespace Disk
	{
		public class Size
		{				
			[DllImport("kernel32.dll")]
			static extern uint GetCompressedFileSizeW([In, MarshalAs(UnmanagedType.LPWStr)] string lpFileName,
			out uint lpFileSizeHigh);
						
			public static ulong SizeOnDisk(string filename)
			{
			  uint High_Order;
			  uint Low_Order;
			  ulong GetSize;
			  FileInfo CurrentFile = new FileInfo(filename);
			  Low_Order = GetCompressedFileSizeW(CurrentFile.FullName, out High_Order);
			  int GetError = Marshal.GetLastWin32Error();
			 if (High_Order == 0 && Low_Order == 0xFFFFFFFF && GetError != 0)
				{
					throw new Win32Exception(GetError);
				}
			 else 
				{ 
					GetSize = ((ulong)High_Order << 32) + Low_Order;
					return GetSize;
				}
			}
		}
	}
"@ -ErrorAction Stop
}
catch{
    Write-Information "Unable to add size on disk class"
}