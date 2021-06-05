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
    public class ChiaParameters
    {
        public int KSize { get; set; }
        public int RAM { get; set; }
        public int Threads { get; set; }
        public ChiaVolume TempVolume { get; set; }
        public ChiaVolume FinalVolume { get; set; }
        public string LogDirectory { get; set; }
        public bool DisableBitField { get; set; }
        public bool ExcludeFinalDirectory { get; set; }

        public string PoolPublicKey { get; set; }
        public string FarmerPublicKey { get; set; }

        public ChiaParameters()
        {
            KSize = 32;
            RAM = 3390;
            Threads = 2;
            LogDirectory = System.IO.Path.Combine(System.Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".chia\\mainnet\\plotter");
        }
        public ChiaParameters(int ksize,int ram,int threads,string logdir)
        {
            KSize = ksize;
            RAM = ram;
            Threads = threads;
            LogDirectory = logdir;
            DisableBitField = true;
            ExcludeFinalDirectory = true;
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
        }
    }

    public class ChiaJob : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;
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

        public int JobNumber { get; set; }
        public string JobName { get; set; }
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
        public int CompletedPlotCount
        {
            get { return _completedplotcount; }
            set
            {
                _completedplotcount = value;
                if (CompletedPlotCount == TotalPlotCount)
                {
                    Status = "Completed";
                }
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

        public ChiaParameters InitialChiaParameters { get; set; }
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
            Queues = new ObservableCollection<ChiaQueue>();
            RunsInProgress = new ObservableCollection<ChiaRun>();
            TempVolumes = new ObservableCollection<ChiaVolume>();
            FinalVolumes = new ObservableCollection<ChiaVolume>();
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
                if (_status == "Finished")
                {
                    ButtonContent = "n/a";
                    ButtonEnabled = false;
                }
                else
                {
                    ButtonEnabled = true;
                }
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

        public ChiaQueue (int jobNum, int queueNum, ChiaParameters parameters)
        {
            JobNumber = jobNum;
            QueueNumber = queueNum;
            CompletedPlotCount = 0;
            StartTime = DateTime.Now;
            Status = "Waiting";
            Progress = 0;
            Runs = new ObservableCollection<ChiaRun>();
            ButtonContent = "Pause";
            ButtonEnabled = false;
            PlottingParameters = parameters;
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

        private void PauseResumeQueue()
        {
            if (Pause)
            {
                ButtonContent = "Pause";
                Status = Status.Replace(" - Pending Pause","");
                Pause = false;
            }
            else
            {
                ButtonContent = "Resume";
                Status = Status + " - Pending Pause";
                Pause = true;
            }
        }

        private ICommand _pauseresumecommand;
        public ICommand PauseResumeCommand
        {
            get
            {
                if (_pauseresumecommand == null)
                    _pauseresumecommand = new RelayCommand(param => PauseResumeQueue());
                return _pauseresumecommand;
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
    
        public int JobNumber { get; set; }
        public int QueueNumber { get; set; }
        public int RunNumber { get; set; }
        public string Phase
        {
            get { return _phasse; }
            set
            {
                _phasse = value;
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
    
        public ChiaRun(int jobnumber, int quequenumber, int runnumber, ChiaParameters chiaparameters)
        {
            JobNumber = jobnumber;
            QueueNumber = quequenumber;
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
        public ObservableCollection<ChiaVolume> SelectedTempVolumes { get; set; }
        public ObservableCollection<ChiaVolume> SelectedFinalVolumes { get; set; }
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
        public char DriveLetter { get; set; }
        public string Label { get; set; }
        public long Size { get; set; }
        public double SizeInGB { get; set; }
        public long FreeSpace
        {
            get { return _freespace; }
            set
            {
                PotentialFinalPlotsRemaining = (int)Math.Floor((decimal)(value / 108877420954));
                double freespace = value / 1073741824;
                double percentfree = value / Size;
                FreeSpaceInGB = Math.Round(freespace,2);
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
        public int PotentialFinalPlotsRemaining
        {
            get { return _potentialfinalplotsremaining; }
            set
            {
                _potentialfinalplotsremaining = value;
                OnPropertyChanged();
            }
        }
        public int MaxConCurrentTempChiaRuns { get; set; }
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

        public ChiaVolume(char driveletter, string label, long size, long freespace)
        {
            DriveLetter = driveletter;
            Label = label;
            Size = size;
            FreeSpace = freespace;
            DirectoryPath = driveletter.ToString() + ":\\";
            CurrentChiaRuns = new ObservableCollection<ChiaRun>();
            PendingFinalRuns = new ObservableCollection<ChiaRun>();

            double freespaceinGB = (double)freespace / 1073741824;
            double percentfree = (double)freespace / (double)size * 100;
            double sizeinGB = (double)size / 1073741824;
            SizeInGB = Math.Round(sizeinGB, 2);
            FreeSpaceInGB = Math.Round(freespaceinGB, 2);
            PercentFree = Math.Round(percentfree, 2);
            PotentialFinalPlotsRemaining = (int)Math.Floor((decimal)freespace / 108877420954);
        }

    }

    public class MainViewModel : INotifyPropertyChanged
    {
        private TimeSpan _fastestrun;
        private TimeSpan _slowestrun;
        private double _tbplottedperday;
        private double _plotsplottedperday;
        private TimeSpan _averagetime;

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

    }
}
"@ -ReferencedAssemblies PresentationFramework,PresentationCore,WindowsBase,"System.Xaml"