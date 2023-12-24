#include "yinglongApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

InputParameters
yinglongApp::validParams()
{
  InputParameters params = MooseApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  return params;
}

yinglongApp::yinglongApp(InputParameters parameters) : MooseApp(parameters)
{
  yinglongApp::registerAll(_factory, _action_factory, _syntax);
}

yinglongApp::~yinglongApp() {}

void 
yinglongApp::registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  ModulesApp::registerAllObjects<yinglongApp>(f, af, s);
  Registry::registerObjectsTo(f, {"yinglongApp"});
  Registry::registerActionsTo(af, {"yinglongApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
yinglongApp::registerApps()
{
  registerApp(yinglongApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
yinglongApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  yinglongApp::registerAll(f, af, s);
}
extern "C" void
yinglongApp__registerApps()
{
  yinglongApp::registerApps();
}
