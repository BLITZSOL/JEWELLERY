﻿//------------------------------------------------------------------------------
// <auto-generated>
//    This code was generated from a template.
//
//    Manual changes to this file may cause unexpected behavior in your application.
//    Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.ComponentModel;
using System.Data.EntityClient;
using System.Data.Objects;
using System.Data.Objects.DataClasses;
using System.Linq;
using System.Runtime.Serialization;
using System.Xml.Serialization;

[assembly: EdmSchemaAttribute()]
namespace THSMVC.Models
{
    #region Contexts
    
    /// <summary>
    /// No Metadata Documentation available.
    /// </summary>
    public partial class LoggerDataStoreEntities : ObjectContext
    {
        #region Constructors
    
        /// <summary>
        /// Initializes a new LoggerDataStoreEntities object using the connection string found in the 'LoggerDataStoreEntities' section of the application configuration file.
        /// </summary>
        public LoggerDataStoreEntities() : base("name=LoggerDataStoreEntities", "LoggerDataStoreEntities")
        {
            this.ContextOptions.LazyLoadingEnabled = true;
            OnContextCreated();
        }
    
        /// <summary>
        /// Initialize a new LoggerDataStoreEntities object.
        /// </summary>
        public LoggerDataStoreEntities(string connectionString) : base(connectionString, "LoggerDataStoreEntities")
        {
            this.ContextOptions.LazyLoadingEnabled = true;
            OnContextCreated();
        }
    
        /// <summary>
        /// Initialize a new LoggerDataStoreEntities object.
        /// </summary>
        public LoggerDataStoreEntities(EntityConnection connection) : base(connection, "LoggerDataStoreEntities")
        {
            this.ContextOptions.LazyLoadingEnabled = true;
            OnContextCreated();
        }
    
        #endregion
    
        #region Partial Methods
    
        partial void OnContextCreated();
    
        #endregion
    
        #region ObjectSet Properties
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        public ObjectSet<Log4Net_Error> Log4Net_Error
        {
            get
            {
                if ((_Log4Net_Error == null))
                {
                    _Log4Net_Error = base.CreateObjectSet<Log4Net_Error>("Log4Net_Error");
                }
                return _Log4Net_Error;
            }
        }
        private ObjectSet<Log4Net_Error> _Log4Net_Error;
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        public ObjectSet<SiteLog> SiteLogs
        {
            get
            {
                if ((_SiteLogs == null))
                {
                    _SiteLogs = base.CreateObjectSet<SiteLog>("SiteLogs");
                }
                return _SiteLogs;
            }
        }
        private ObjectSet<SiteLog> _SiteLogs;

        #endregion

        #region AddTo Methods
    
        /// <summary>
        /// Deprecated Method for adding a new object to the Log4Net_Error EntitySet. Consider using the .Add method of the associated ObjectSet&lt;T&gt; property instead.
        /// </summary>
        public void AddToLog4Net_Error(Log4Net_Error log4Net_Error)
        {
            base.AddObject("Log4Net_Error", log4Net_Error);
        }
    
        /// <summary>
        /// Deprecated Method for adding a new object to the SiteLogs EntitySet. Consider using the .Add method of the associated ObjectSet&lt;T&gt; property instead.
        /// </summary>
        public void AddToSiteLogs(SiteLog siteLog)
        {
            base.AddObject("SiteLogs", siteLog);
        }

        #endregion

    }

    #endregion

    #region Entities
    
    /// <summary>
    /// No Metadata Documentation available.
    /// </summary>
    [EdmEntityTypeAttribute(NamespaceName="THSMVCModel", Name="Log4Net_Error")]
    [Serializable()]
    [DataContractAttribute(IsReference=true)]
    public partial class Log4Net_Error : EntityObject
    {
        #region Factory Method
    
        /// <summary>
        /// Create a new Log4Net_Error object.
        /// </summary>
        /// <param name="id">Initial value of the Id property.</param>
        /// <param name="date">Initial value of the Date property.</param>
        /// <param name="thread">Initial value of the Thread property.</param>
        /// <param name="level">Initial value of the Level property.</param>
        /// <param name="logger">Initial value of the Logger property.</param>
        /// <param name="message">Initial value of the Message property.</param>
        /// <param name="exception">Initial value of the Exception property.</param>
        /// <param name="userID">Initial value of the UserID property.</param>
        public static Log4Net_Error CreateLog4Net_Error(global::System.Int32 id, global::System.DateTime date, global::System.String thread, global::System.String level, global::System.String logger, global::System.String message, global::System.String exception, global::System.String userID)
        {
            Log4Net_Error log4Net_Error = new Log4Net_Error();
            log4Net_Error.Id = id;
            log4Net_Error.Date = date;
            log4Net_Error.Thread = thread;
            log4Net_Error.Level = level;
            log4Net_Error.Logger = logger;
            log4Net_Error.Message = message;
            log4Net_Error.Exception = exception;
            log4Net_Error.UserID = userID;
            return log4Net_Error;
        }

        #endregion

        #region Primitive Properties
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=true, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.Int32 Id
        {
            get
            {
                return _Id;
            }
            set
            {
                if (_Id != value)
                {
                    OnIdChanging(value);
                    ReportPropertyChanging("Id");
                    _Id = StructuralObject.SetValidValue(value);
                    ReportPropertyChanged("Id");
                    OnIdChanged();
                }
            }
        }
        private global::System.Int32 _Id;
        partial void OnIdChanging(global::System.Int32 value);
        partial void OnIdChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.DateTime Date
        {
            get
            {
                return _Date;
            }
            set
            {
                OnDateChanging(value);
                ReportPropertyChanging("Date");
                _Date = StructuralObject.SetValidValue(value);
                ReportPropertyChanged("Date");
                OnDateChanged();
            }
        }
        private global::System.DateTime _Date;
        partial void OnDateChanging(global::System.DateTime value);
        partial void OnDateChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.String Thread
        {
            get
            {
                return _Thread;
            }
            set
            {
                OnThreadChanging(value);
                ReportPropertyChanging("Thread");
                _Thread = StructuralObject.SetValidValue(value, false);
                ReportPropertyChanged("Thread");
                OnThreadChanged();
            }
        }
        private global::System.String _Thread;
        partial void OnThreadChanging(global::System.String value);
        partial void OnThreadChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.String Level
        {
            get
            {
                return _Level;
            }
            set
            {
                OnLevelChanging(value);
                ReportPropertyChanging("Level");
                _Level = StructuralObject.SetValidValue(value, false);
                ReportPropertyChanged("Level");
                OnLevelChanged();
            }
        }
        private global::System.String _Level;
        partial void OnLevelChanging(global::System.String value);
        partial void OnLevelChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.String Logger
        {
            get
            {
                return _Logger;
            }
            set
            {
                OnLoggerChanging(value);
                ReportPropertyChanging("Logger");
                _Logger = StructuralObject.SetValidValue(value, false);
                ReportPropertyChanged("Logger");
                OnLoggerChanged();
            }
        }
        private global::System.String _Logger;
        partial void OnLoggerChanging(global::System.String value);
        partial void OnLoggerChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.String Message
        {
            get
            {
                return _Message;
            }
            set
            {
                OnMessageChanging(value);
                ReportPropertyChanging("Message");
                _Message = StructuralObject.SetValidValue(value, false);
                ReportPropertyChanged("Message");
                OnMessageChanged();
            }
        }
        private global::System.String _Message;
        partial void OnMessageChanging(global::System.String value);
        partial void OnMessageChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.String Exception
        {
            get
            {
                return _Exception;
            }
            set
            {
                OnExceptionChanging(value);
                ReportPropertyChanging("Exception");
                _Exception = StructuralObject.SetValidValue(value, false);
                ReportPropertyChanged("Exception");
                OnExceptionChanged();
            }
        }
        private global::System.String _Exception;
        partial void OnExceptionChanging(global::System.String value);
        partial void OnExceptionChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.String UserID
        {
            get
            {
                return _UserID;
            }
            set
            {
                OnUserIDChanging(value);
                ReportPropertyChanging("UserID");
                _UserID = StructuralObject.SetValidValue(value, false);
                ReportPropertyChanged("UserID");
                OnUserIDChanged();
            }
        }
        private global::System.String _UserID;
        partial void OnUserIDChanging(global::System.String value);
        partial void OnUserIDChanged();

        #endregion

    
    }
    
    /// <summary>
    /// No Metadata Documentation available.
    /// </summary>
    [EdmEntityTypeAttribute(NamespaceName="THSMVCModel", Name="SiteLog")]
    [Serializable()]
    [DataContractAttribute(IsReference=true)]
    public partial class SiteLog : EntityObject
    {
        #region Factory Method
    
        /// <summary>
        /// Create a new SiteLog object.
        /// </summary>
        /// <param name="id">Initial value of the ID property.</param>
        /// <param name="timeStamp">Initial value of the TimeStamp property.</param>
        /// <param name="action">Initial value of the Action property.</param>
        /// <param name="controller">Initial value of the Controller property.</param>
        public static SiteLog CreateSiteLog(global::System.Int32 id, global::System.DateTime timeStamp, global::System.String action, global::System.String controller)
        {
            SiteLog siteLog = new SiteLog();
            siteLog.ID = id;
            siteLog.TimeStamp = timeStamp;
            siteLog.Action = action;
            siteLog.Controller = controller;
            return siteLog;
        }

        #endregion

        #region Primitive Properties
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=true, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.Int32 ID
        {
            get
            {
                return _ID;
            }
            set
            {
                if (_ID != value)
                {
                    OnIDChanging(value);
                    ReportPropertyChanging("ID");
                    _ID = StructuralObject.SetValidValue(value);
                    ReportPropertyChanged("ID");
                    OnIDChanged();
                }
            }
        }
        private global::System.Int32 _ID;
        partial void OnIDChanging(global::System.Int32 value);
        partial void OnIDChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.DateTime TimeStamp
        {
            get
            {
                return _TimeStamp;
            }
            set
            {
                OnTimeStampChanging(value);
                ReportPropertyChanging("TimeStamp");
                _TimeStamp = StructuralObject.SetValidValue(value);
                ReportPropertyChanged("TimeStamp");
                OnTimeStampChanged();
            }
        }
        private global::System.DateTime _TimeStamp;
        partial void OnTimeStampChanging(global::System.DateTime value);
        partial void OnTimeStampChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.String Action
        {
            get
            {
                return _Action;
            }
            set
            {
                OnActionChanging(value);
                ReportPropertyChanging("Action");
                _Action = StructuralObject.SetValidValue(value, false);
                ReportPropertyChanged("Action");
                OnActionChanged();
            }
        }
        private global::System.String _Action;
        partial void OnActionChanging(global::System.String value);
        partial void OnActionChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=false)]
        [DataMemberAttribute()]
        public global::System.String Controller
        {
            get
            {
                return _Controller;
            }
            set
            {
                OnControllerChanging(value);
                ReportPropertyChanging("Controller");
                _Controller = StructuralObject.SetValidValue(value, false);
                ReportPropertyChanged("Controller");
                OnControllerChanged();
            }
        }
        private global::System.String _Controller;
        partial void OnControllerChanging(global::System.String value);
        partial void OnControllerChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=true)]
        [DataMemberAttribute()]
        public global::System.String IPAddress
        {
            get
            {
                return _IPAddress;
            }
            set
            {
                OnIPAddressChanging(value);
                ReportPropertyChanging("IPAddress");
                _IPAddress = StructuralObject.SetValidValue(value, true);
                ReportPropertyChanged("IPAddress");
                OnIPAddressChanged();
            }
        }
        private global::System.String _IPAddress;
        partial void OnIPAddressChanging(global::System.String value);
        partial void OnIPAddressChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=true)]
        [DataMemberAttribute()]
        public global::System.String URL
        {
            get
            {
                return _URL;
            }
            set
            {
                OnURLChanging(value);
                ReportPropertyChanging("URL");
                _URL = StructuralObject.SetValidValue(value, true);
                ReportPropertyChanged("URL");
                OnURLChanged();
            }
        }
        private global::System.String _URL;
        partial void OnURLChanging(global::System.String value);
        partial void OnURLChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=true)]
        [DataMemberAttribute()]
        public global::System.String HostAddress
        {
            get
            {
                return _HostAddress;
            }
            set
            {
                OnHostAddressChanging(value);
                ReportPropertyChanging("HostAddress");
                _HostAddress = StructuralObject.SetValidValue(value, true);
                ReportPropertyChanged("HostAddress");
                OnHostAddressChanged();
            }
        }
        private global::System.String _HostAddress;
        partial void OnHostAddressChanging(global::System.String value);
        partial void OnHostAddressChanged();
    
        /// <summary>
        /// No Metadata Documentation available.
        /// </summary>
        [EdmScalarPropertyAttribute(EntityKeyProperty=false, IsNullable=true)]
        [DataMemberAttribute()]
        public global::System.String UserID
        {
            get
            {
                return _UserID;
            }
            set
            {
                OnUserIDChanging(value);
                ReportPropertyChanging("UserID");
                _UserID = StructuralObject.SetValidValue(value, true);
                ReportPropertyChanged("UserID");
                OnUserIDChanged();
            }
        }
        private global::System.String _UserID;
        partial void OnUserIDChanging(global::System.String value);
        partial void OnUserIDChanged();

        #endregion

    
    }

    #endregion

    
}
