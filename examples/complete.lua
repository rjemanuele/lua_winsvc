local winsvc = require('winsvc')
local winsvcaux = require('winsvcaux')

local svcname = 'Test Lua Service'
local gSvcStatusHandle
local gSvcStatus = {}
local gRunning = true


local function ReportSvcStatus(dwCurrentState, dwWin32ExitCode, dwWaitHint)
  local dwCheckPoint = 1

  -- Fill in the SERVICE_STATUS structure.

  gSvcStatus.dwCurrentState = dwCurrentState
  gSvcStatus.dwWin32ExitCode = dwWin32ExitCode
  gSvcStatus.dwWaitHint = dwWaitHint

  if dwCurrentState == winsvc.SERVICE_START_PENDING then
    gSvcStatus.dwControlsAccepted = 0
  else
    gSvcStatus.dwControlsAccepted = winsvc.SERVICE_ACCEPT_STOP
  end

  if dwCurrentState == winsvc.SERVICE_RUNNING or
    dwCurrentState == winsvc.SERVICE_STOPPED then
    gSvcStatus.dwCheckPoint = 0
  else
    dwCheckPoint = dwCheckPoint + 1
    gSvcStatus.dwCheckPoint = dwCheckPoint
  end

  -- Report the status of the service to the SCM.
  winsvc.SetServiceStatus(gSvcStatusHandle, gSvcStatus)
end


local function SvcCtrlHandler(dwCtrl)
  -- Handle the requested control code. 

  if dwCtrl == winsvc.SERVICE_CONTROL_STOP then 
    ReportSvcStatus(winsvc.SERVICE_STOP_PENDING, NO_ERROR, 0)

    -- Signal the service to stop.

    gRunning = false
    ReportSvcStatus(gSvcStatus.dwCurrentState, winsvc.NO_ERROR, 0)
         
    return
  elseif dwCtrl == winsvc.SERVICE_CONTROL_INTERROGATE then 
    return
  end
end


local function SvcReportEvent(msg)
  -- Log that somewhere
end


local function SvcInit(args)
  -- TO_DO: Declare and set any required variables.
  --   Be sure to periodically call ReportSvcStatus() with 
  --   SERVICE_START_PENDING. If initialization fails, call
  --   ReportSvcStatus with SERVICE_STOPPED.

  -- Create an event. The control handler function, SvcCtrlHandler,
  -- signals this event when it receives the stop control code.

  ReportSvcStatus(winsvc.SERVICE_RUNNING, winsvc.NO_ERROR, 0)

  -- TO_DO: Perform work until service stops.

  while gRunning do
    -- Do Stuff
    winsvcaux.dbgSleep(1000)
  end

  ReportSvcStatus(winsvc.SERVICE_STOPPED, winsvc.NO_ERROR, 0);
end


local function SvcMain(args)
  -- Register the handler function for the service

  gSvcStatusHandle = winsvc.RegisterServiceCtrlHandler(svcname, SvcCtrlHandler)

  if not gSvcStatusHandle then
    SvcReportEvent('RegisterServiceCtrlHandler Failed') 
    return
  end

  -- These SERVICE_STATUS members remain as set here

  gSvcStatus.dwServiceType = winsvc.SERVICE_WIN32_OWN_PROCESS
  gSvcStatus.dwServiceSpecificExitCode = 0

  -- Report initial status to the SCM

  ReportSvcStatus(winsvc.SERVICE_START_PENDING, winsvc.NO_ERROR, 3000)

  -- Perform service-specific initialization and work.

  SvcInit(args)
end


local function SvcInstall()
  local svcPath, err = winsvcaux.GetModuleFileName('')
  if svcPath == nil then
    print('Cannot install service, service path unobtainable', err)
    return
  end

  -- Get a handle to the SCM database
  local schSCManager, err = winsvc.OpenSCManager(nil, nil, winsvc.SC_MANAGER_ALL_ACCESS)
  if schSCManager == nil then
    print('OpenSCManager failed', err)
    return
  end

  -- Create the Service
  local schService, err = winsvc.CreateService(
    schSCManager,
    svcname,
    svcname,
    winsvc.SERVICE_ALL_ACCESS,
    winsvc.SERVICE_WIN32_OWN_PROCESS,
    winsvc.SERVICE_DEMAND_START,
    winsvc.SERVICE_ERROR_NORMAL,
    svcPath,
    nil,
    nil,
    nil,
    nil,
    nil)

  if schService == nil then
    print('CreateService failed', err)
    winsvc.CloseServiceHandle(schSCManager)
    return
  end

  print('Service installed successfully')

  winsvc.CloseServiceHandle(schService)
  winsvc.CloseServiceHandle(schSCManager)

end


local function SvcDelete()
  -- Get a handle to the SCM database
  local schSCManager = winsvc.OpenSCManager(nil, nil, winsvc.SC_MANAGER_ALL_ACCESS)
  if schSCManager == nil then
    print('OpenSCManager failed', winsvcaux.GetLastErrorString())
    return
  end

  -- Open the Service
  local schService = winsvc.OpenService(
    schSCManager,
    svcname,
    winsvc.DELETE)

  if schService == nil then
    print('OpenService failed', winsvcaux.GetLastErrorString())
    winsvc.CloseServiceHandle(schSCManager)
    return
  end

  -- Delete the Service
  local schService = winsvc.OpenService(
    schSCManager,
    svcname,
    winsvc.DELETE)

  if not winsvc.DeleteService(schService) then
    print('DeleteService failed', winsvcaux.GetLastErrorString())
  else
    print('DeleteService succeeded')
  end

  winsvc.CloseServiceHandle(schService)
  winsvc.CloseServiceHandle(schSCManager)

end


-- Main Code

if args[2] == 'install' then
  SvcInstall()
  return
elseif args[2] == 'delete' then
  SvcDelete()
  return
end

local DispatchTable = [{
  'ServiceName' = svcname,
  'ServiceProc' = svcmain
  }]

if not StartServiceCtrlDispatcher(DispatchTable) then
  SvcReportEvent('StartServiceCtrlDispatcher Succeeded')
end
